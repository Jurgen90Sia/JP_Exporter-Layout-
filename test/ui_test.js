const {test} = require('node:test');
const assert = require('node:assert/strict');
const preview = require('../jp_exporter_layout/ui/preview.js');
test('viewport flips CAD y and pads a flat drawing', () => {
  assert.deepEqual(preview.viewport([0, 0, 600, 800]), [-16, -816, 632, 832]);
  assert.ok(preview.viewport([0, 0, 0, 0])[2] > 0);
});
test('rejects malformed, nonfinite and reversed bounds', () => {
  for (const bounds of [[], [0,0,NaN,1], [2,0,1,1]]) {
    assert.throws(() => preview.viewport(bounds));
  }
});
test('validates drawing payload before rendering', () => {
  assert.throws(() => preview.validate({}));
  assert.throws(() => preview.validate({units:'mm',bounds:[0,0,1,1], edges:[{points:[[0,0],[Infinity,1]]}]}));
  assert.doesNotThrow(() => preview.validate({units:'mm',bounds:[0,0,1,1],edges:[{points:[[0,0],[1,1]]}]}));
});

function fakeDocument() {
  class Element {
    constructor() { this.children = []; this.attrs = {}; this.value = 'front'; this.disabled = false; }
    setAttribute(key,value) { this.attrs[key] = String(value); }
    appendChild(child) { this.children.push(child); }
    addEventListener(name,fn) { this[name] = fn; }
    set textContent(value) { this.text = value; this.children = []; }
    get textContent() { return this.text; }
  }
  const elements = Object.fromEntries(['preview','status','drawing','view','dimensions','scale','render_mode','export_dxf','save_snapshot','open_snapshot','fit'].map(id=>[id,new Element()]));
  elements.scale.value = '1';
  elements.render_mode.value = 'wireframe';
  return {getElementById:id=>elements[id],createDocumentFragment:()=>new Element(),createElementNS:()=>new Element()};
}
test('click sends versioned request and response creates SVG geometry', () => {
  const doc = fakeDocument();
  let payload;
  const controller = preview.mount(doc,{preview:value=>{payload=JSON.parse(value);}});
  doc.getElementById('preview').click();
  assert.deepEqual(payload,{schema_version:1,view:'front'});
  assert.equal(doc.getElementById('preview').disabled,true);
  controller.receive({ok:true,drawing:{units:'mm',view:'front',bounds:[0,0,600,800],edges:[{points:[[0,0],[600,800]]}]}});
  const drawing = doc.getElementById('drawing');
  assert.equal(drawing.attrs.viewBox,'-16 -816 632 832');
  assert.equal(drawing.children[0].children[0].attrs.y2,'-800');
  assert.equal(doc.getElementById('preview').disabled,false);
  assert.match(doc.getElementById('status').textContent,/wireframe/);
  controller.receive({ok:false,error:'Select geometry'});
  assert.equal(drawing.children.length,0);
  assert.equal(doc.getElementById('status').textContent,'Select geometry');
});
test('missing bridge is actionable and does not disable button', () => {
  const doc = fakeDocument();
  preview.mount(doc,null);
  doc.getElementById('preview').click();
  assert.match(doc.getElementById('status').textContent,/SketchUp/);
  assert.equal(doc.getElementById('preview').disabled,false);
});
test('malformed response clears stale geometry and reports validation failure', () => {
  const doc = fakeDocument();
  const controller = preview.mount(doc,null);
  controller.receive({ok:true,drawing:{units:'inches'}});
  assert.match(doc.getElementById('status').textContent,/Invalid/);
  assert.equal(doc.getElementById('drawing').children.length,0);
});

test('timeout clears previous drawing and allows retry', (t) => {
  let timeout;
  t.mock.method(global, 'setTimeout', (callback) => { timeout = callback; return 1; });
  t.mock.method(global, 'clearTimeout', () => {});
  const doc = fakeDocument();
  const controller = preview.mount(doc, {preview: () => {}});
  controller.receive({ok:true,drawing:{units:'mm',view:'front',bounds:[0,0,1,1],edges:[{points:[[0,0],[1,1]]}]}});
  doc.getElementById('preview').click();
  timeout();
  assert.equal(doc.getElementById('drawing').children.length,0);
  assert.equal(doc.getElementById('preview').disabled,false);
});
test('bridge exception clears earlier drawing', () => {
  const doc = fakeDocument();
  const controller = preview.mount(doc, {preview: () => {throw new Error('Unavailable');}});
  controller.receive({ok:true,drawing:{units:'mm',view:'front',bounds:[0,0,1,1],edges:[{points:[[0,0],[1,1]]}]}});
  doc.getElementById('preview').click();
  assert.equal(doc.getElementById('drawing').children.length,0);
  assert.equal(doc.getElementById('status').textContent,'Unavailable');
});

test('dimension checkbox includes physical scale and renders measured annotation', () => {
  const doc = fakeDocument();
  doc.getElementById('dimensions').checked = true;
  doc.getElementById('scale').value = '0.1';
  let sent;
  const controller = preview.mount(doc,{preview:value=>{sent=JSON.parse(value);}});
  doc.getElementById('preview').click();
  assert.equal(sent.dimensions,true);
  assert.equal(sent.scale,0.1);
  controller.receive({ok:true,drawing:{units:'mm',view:'front',bounds:[0,0,600,800],
    edges:[{points:[[0,0],[600,800]]}],dimensions:[{type:'dimension',axis:'horizontal',value_mm:600,
      text:'600 mm', anchors:[[0,0],[600,0]],line:[[0,-100],[600,-100]],text_at:[300,-100]}]}});
  assert.match(JSON.stringify(doc.getElementById('drawing').children),/600 mm/);
  assert.equal(doc.getElementById('export_dxf').disabled,false);
});
test('export command uses registry and stays disabled before successful drawing', () => {
  const doc = fakeDocument();
  let sent;
  const controller = preview.mount(doc,{command:value=>{sent=JSON.parse(value);}});
  assert.equal(doc.getElementById('export_dxf').disabled,true);
  controller.receive({ok:true,drawing:{units:'mm',view:'front',bounds:[0,0,1,1],edges:[{points:[[0,0],[1,1]]}]}});
  doc.getElementById('export_dxf').click();
  assert.equal(sent.command,'export_dxf');
  controller.receive({ok:true,message:'Saved DXF.'});
  assert.equal(doc.getElementById('status').textContent,'Saved DXF.');
  assert.ok(doc.getElementById('drawing').children.length);
});
test('hidden line control reaches backend and hidden segments receive dashed class', () => {
  const doc = fakeDocument();
  doc.getElementById('render_mode').value = 'hidden';
  let sent;
  const controller = preview.mount(doc,{preview:value=>{sent=JSON.parse(value);}});
  doc.getElementById('preview').click();
  assert.equal(sent.render_mode,'hidden');
  controller.receive({ok:true,drawing:{units:'mm',view:'front',render_mode:'hidden',bounds:[0,0,1,1],
    edges:[{role:'hidden',points:[[0,0],[1,1]]}]}});
  assert.equal(doc.getElementById('drawing').children[0].children[0].attrs.class,'hidden-line');
  controller.receive({ok:false,error:'File unavailable',preserve_drawing:true});
  assert.equal(doc.getElementById('drawing').children.length,1);
});
