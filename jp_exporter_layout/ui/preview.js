/* global sketchup */
(function (root) {
  'use strict';
  function viewport(bounds) {
    if (!Array.isArray(bounds) || bounds.length !== 4 || !bounds.every(Number.isFinite) ||
        bounds[2] < bounds[0] || bounds[3] < bounds[1]) throw new Error('Invalid drawing bounds.');
    var width = bounds[2] - bounds[0], height = bounds[3] - bounds[1];
    var padding = Math.max(width, height, 1) * 0.02;
    return [bounds[0] - padding, -bounds[3] - padding, width + padding * 2, height + padding * 2];
  }
  function validate(drawing) {
    if (!drawing || drawing.units !== 'mm' || !Array.isArray(drawing.edges) || drawing.edges.length > 20000) {
      throw new Error('Invalid drawing payload.');
    }
    viewport(drawing.bounds);
    drawing.edges.forEach(function (edge) {
      if (!edge || !Array.isArray(edge.points) || edge.points.length !== 2 || !edge.points.every(function (p) {
        return Array.isArray(p) && p.length === 2 && p.every(Number.isFinite);
      })) throw new Error('Invalid edge.');
    });
  }
  function mount(doc, bridge) {
    var button = doc.getElementById('preview'), status = doc.getElementById('status');
    var svg = doc.getElementById('drawing'), view = doc.getElementById('view');
    var timer, lastBounds, hasDrawing = false;
    var dimensions = doc.getElementById('dimensions'), scale = doc.getElementById('scale');
    var registry = {export_dxf: true, save_snapshot: true, open_snapshot: false, analyze_materials: false, export_materials: false, export_sheet_svg: false, export_native: false};
    var materials = doc.getElementById('materials');
    var fit = doc.getElementById('fit');
    function controls(busy) {
      button.disabled = busy;
      Object.keys(registry).forEach(function (name) {
        var control = doc.getElementById(name);
        if (control) control.disabled = busy || (registry[name] && !hasDrawing);
      });
      if (fit) fit.disabled = busy || !hasDrawing;
    }
    function unlock() { clearTimeout(timer); controls(false); }
    function clearDrawing() { svg.textContent = ''; hasDrawing = false; lastBounds = null; controls(false); }
    function addLine(parent, points, className) {
      var line = doc.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1',points[0][0]); line.setAttribute('y1',-points[0][1]);
      line.setAttribute('x2',points[1][0]); line.setAttribute('y2',-points[1][1]);
      line.setAttribute('vector-effect','non-scaling-stroke');
      if (className) line.setAttribute('class',className);
      parent.appendChild(line);
    }
    function receive(result) {
      unlock();
      try {
        if (!result || !result.ok) throw new Error(result && result.error || 'Preview failed.');
        if (result.analysis) {
          if (materials) materials.textContent = '';
          var a = result.analysis;
          if (a.units !== 'mm' || a.area_units !== 'mm2' || !Array.isArray(a.materials) ||
              ![a.group_count,a.component_instance_count,a.face_count].every(function (n) { return Number.isInteger(n) && n >= 0; }) ||
              !Number.isFinite(a.front_area_mm2) || a.front_area_mm2 < 0) throw new Error('Invalid material report.');
          var lines = [a.group_count + ' groups · ' + a.component_instance_count + ' instances · ' + a.face_count + ' faces',
            'Front surfaces: ' + (a.front_area_mm2/1000000).toFixed(4) + ' m²'];
          a.materials.forEach(function (m) {
            if (typeof m.name !== 'string' || ![m.front_area_mm2,m.back_area_mm2].every(function (n) {
              return Number.isFinite(n) && n >= 0;
            })) throw new Error('Invalid material report.');
            lines.push(m.name + ': front ' + (m.front_area_mm2/1000000).toFixed(4) +
              ' m² · back ' + (m.back_area_mm2/1000000).toFixed(4) + ' m²');
          });
          if (materials) materials.textContent = lines.join('\n');
        }
        if (result.message && !result.drawing) { status.textContent = result.message; return; }
        var drawing = result.drawing;
        validate(drawing);
        var fragment = doc.createDocumentFragment();
        drawing.edges.forEach(function (edge) {
          addLine(fragment,edge.points,edge.role === 'hidden' ? 'hidden-line' : null);
        });
        var bounds = drawing.bounds.slice();
        (drawing.dimensions || []).forEach(function (d) {
          if (!d || !Array.isArray(d.line) || !Array.isArray(d.anchors) || d.line.length !== 2 || d.anchors.length !== 2 ||
              !d.line.concat(d.anchors,[d.text_at]).every(function (p) {
                return Array.isArray(p) && p.length === 2 && p.every(Number.isFinite);
              }) || typeof d.text !== 'string' || d.text.length > 100) throw new Error('Invalid dimension.');
          addLine(fragment,d.line,'dimension');
          d.line.forEach(function (p,i) {
            addLine(fragment,[d.anchors[i],p],'dimension');
            var tick = (d.text_height_mm || Math.max(bounds[2]-bounds[0],bounds[3]-bounds[1],1)*0.02)/3;
            addLine(fragment,[[p[0]-tick,p[1]-tick],[p[0]+tick,p[1]+tick]],'dimension');
            bounds = [Math.min(bounds[0],p[0]-tick*4),Math.min(bounds[1],p[1]-tick*4),
              Math.max(bounds[2],p[0]+tick*4),Math.max(bounds[3],p[1]+tick*4)];
          });
          var text = doc.createElementNS('http://www.w3.org/2000/svg','text');
          text.setAttribute('x',d.text_at[0]); text.setAttribute('y',-d.text_at[1]);
          text.setAttribute('dy','-0.25em');
          text.setAttribute('font-size',d.text_height_mm || Math.max(bounds[2]-bounds[0],bounds[3]-bounds[1],1)*0.02);
          text.setAttribute('text-anchor','middle');
          text.setAttribute('class','dimension-text'); text.textContent = d.text; fragment.appendChild(text);
        });
        svg.textContent = '';
        lastBounds = bounds;
        svg.setAttribute('viewBox', viewport(bounds).join(' '));
        svg.appendChild(fragment);
        hasDrawing = true; controls(false);
        status.textContent = drawing.edges.length + ' segments · ' + drawing.view + ' · mm · ' +
          (drawing.render_mode && drawing.render_mode !== 'wireframe' ? drawing.render_mode + ' (opaque-face processing)' : 'wireframe (occluded edges included)');
      } catch (error) {
        if (!result || !result.preserve_drawing) clearDrawing();
        status.textContent = error.message;
      }
    }
    button.addEventListener('click', function () {
      clearDrawing();
      if (!bridge || typeof bridge.preview !== 'function') {
        status.textContent = 'Open this preview from SketchUp to read the current selection.'; return;
      }
      controls(true);
      status.textContent = 'Extracting current selection…';
      timer = setTimeout(function () { unlock(); status.textContent = 'No response. Try a smaller selection.'; }, 30000);
      try {
        var request = {schema_version: 1, view: view.value};
        var mode = doc.getElementById('render_mode');
        if (mode && mode.value !== 'wireframe') request.render_mode = mode.value;
        if (dimensions && dimensions.checked) { request.dimensions = true; request.scale = Number(scale.value); }
        bridge.preview(JSON.stringify(request));
      }
      catch (error) { unlock(); status.textContent = error.message; }
    });
    Object.keys(registry).forEach(function (name) {
      var control = doc.getElementById(name);
      if (control) control.addEventListener('click',function () {
        if (control.disabled) return;
        if (!bridge || typeof bridge.command !== 'function') { status.textContent = 'Open this command from SketchUp.'; return; }
        controls(true);
        timer = setTimeout(function () { unlock(); status.textContent = 'File operation is still waiting. Check SketchUp dialogs.'; },30000);
        try {
          var request = {schema_version:1,command:name};
          if (name === 'export_sheet_svg' || name === 'export_native') {
            request.paper = doc.getElementById('paper').value;
            request.orientation = doc.getElementById('orientation').value;
            var sheetScale = doc.getElementById('sheet_scale').value;
            request.sheet_scale = sheetScale === 'auto' ? 'auto' : Number(sheetScale);
          }
          bridge.command(JSON.stringify(request));
        }
        catch (error) { unlock(); status.textContent = error.message; }
      });
    });
    if (fit) fit.addEventListener('click',function () { if (lastBounds) svg.setAttribute('viewBox',viewport(lastBounds).join(' ')); });
    controls(false);
    return {receive: receive};
  }
  var api = {viewport: viewport, validate: validate, mount: mount};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (root && root.document) root.JPPreview = mount(root.document, root.sketchup);
}(typeof window === 'undefined' ? null : window));
