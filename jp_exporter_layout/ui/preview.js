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
    var timer;
    function unlock() { clearTimeout(timer); button.disabled = false; }
    function receive(result) {
      unlock();
      try {
        if (!result.ok) throw new Error(result.error || 'Preview failed.');
        var drawing = result.drawing;
        validate(drawing);
        var fragment = doc.createDocumentFragment();
        drawing.edges.forEach(function (edge) {
          var line = doc.createElementNS('http://www.w3.org/2000/svg', 'line');
          line.setAttribute('x1', edge.points[0][0]); line.setAttribute('y1', -edge.points[0][1]);
          line.setAttribute('x2', edge.points[1][0]); line.setAttribute('y2', -edge.points[1][1]);
          line.setAttribute('vector-effect', 'non-scaling-stroke');
          fragment.appendChild(line);
        });
        svg.textContent = '';
        svg.setAttribute('viewBox', viewport(drawing.bounds).join(' '));
        svg.appendChild(fragment);
        status.textContent = drawing.edges.length + ' edges · ' + drawing.view + ' · mm · wireframe (occluded edges included)';
      } catch (error) {
        svg.textContent = '';
        status.textContent = error.message;
      }
    }
    button.addEventListener('click', function () {
      svg.textContent = '';
      if (!bridge || typeof bridge.preview !== 'function') {
        status.textContent = 'Open this preview from SketchUp to read the current selection.'; return;
      }
      button.disabled = true;
      status.textContent = 'Extracting current selection…';
      timer = setTimeout(function () { unlock(); status.textContent = 'No response. Try a smaller selection.'; }, 30000);
      try { bridge.preview(JSON.stringify({schema_version: 1, view: view.value})); }
      catch (error) { unlock(); status.textContent = error.message; }
    });
    return {receive: receive};
  }
  var api = {viewport: viewport, validate: validate, mount: mount};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (root && root.document) root.JPPreview = mount(root.document, root.sketchup);
}(typeof window === 'undefined' ? null : window));
