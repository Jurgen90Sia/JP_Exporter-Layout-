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
  const elements = Object.fromEntries(['preview','status','drawing','view'].map(id=>[id,new Element()]));
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
