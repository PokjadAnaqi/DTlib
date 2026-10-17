const fs=require('fs'),vm=require('vm'),assert=require('assert');
class Element {
 constructor(tag){this.tag=tag;this.children=[];this.style={};this.className='';this.classList={add:n=>this.className+=' '+n};}
 appendChild(c){c.parent=this;this.children.push(c);return c;}
 append(...c){c.forEach(x=>this.appendChild(x));}
 replaceChildren(){this.children=[];}
 setAttribute(k,v){this[k]=v;}
 remove(){if(this.parent)this.parent.children=this.parent.children.filter(x=>x!==this);}
}
const root=new Element('root'),timers=new Map();let tick=0,seq=0;
const intervals=new Map();
const ctx={Date:{now:()=>tick},setInterval:f=>{intervals.set(++seq,f);return seq;},clearInterval:id=>intervals.delete(id),document:{querySelector:()=>root,createElement:t=>new Element(t)},setTimeout:(f,ms)=>{timers.set(++seq,{f,at:tick+ms});return seq;},clearTimeout:id=>timers.delete(id)};
vm.createContext(ctx);vm.runInContext(fs.readFileSync(__dirname+'/../html/notify.js','utf8'),ctx);
function advance(ms){const end=tick+ms;while(true){const next=[...timers].sort((a,b)=>a[1].at-b[1].at)[0];if(!next||next[1].at>end)break;tick=next[1].at;timers.delete(next[0]);next[1].f();}tick=end;}
const send=d=>ctx.notify({layout:'banner',position:'top-right',duration:1000,maxVisible:1,countdown:false,...d});
send({title:'A',description:'<img src=x onerror=alert(1)>',image:'javascript:alert(1)'});
assert.equal(root.children[0].children.length,1);
let card=root.children[0].children[0];assert.equal(card.children[1].children[1].textContent,'<img src=x onerror=alert(1)>');assert.equal(card.children[0].children.length,1);
send({title:'B'});assert.equal(root.children[0].children.length,1);advance(1180);assert.equal(root.children[0].children[0].children[1].children[0].textContent,'B');
send({title:'B'});assert.equal(root.children[0].children[0].children[2].textContent,'×2');
vm.runInContext('DTNotifications.clear()',ctx);assert.equal(timers.size,0);assert.equal(root.children.length,0);
send({id:'same',title:'OLD'});advance(500);send({id:'same',title:'NEW'});assert.equal(root.children[0].children.length,1);advance(600);assert.equal(root.children[0].children.length,1);advance(580);assert.equal(root.children[0].children.length,0);
send({image:'nui://ox_inventory/web/images/pill.png',title:'IMAGE',progress:false});card=root.children[0].children[0];const picture=card.children[0];assert.equal(picture.children[1].tag,'img');picture.children[1].onerror();assert.equal(picture.children.length,1);assert.equal(picture.children[0].hidden,false);assert.equal(card.children.length,2);
vm.runInContext('DTNotifications.clear()',ctx);
send({id:'protection',title:'Protection',duration:1800000,countdown:true});card=root.children[0].children[0];assert.equal(card.remaining,undefined);assert.equal(card.children[1].children.at(-1).textContent,'30 minutes 0 seconds');advance(1000);[...intervals.values()].forEach(f=>f());assert.equal(card.children[1].children.at(-1).textContent,'29 minutes 59 seconds');vm.runInContext("DTNotifications.remove('protection')",ctx);assert.equal(intervals.size,0);assert.equal(root.children[0].children.length,0);
console.log('Native banners: queue/lifetime, ID replacement, stacking, safe text, image fallback and timer cleanup PASS');
vm.runInContext('DTNotifications.clear()',ctx);
send({id:'blocker',title:'Blocker',duration:5000});
send({id:'expired',title:'Expired queued banner',expiresAt:1001,serverTime:1000});
advance(5180);assert.equal(root.children[0].children.length,0);
send({id:'absolute',title:'Absolute',expiresAt:1100,serverTime:1000,countdown:true});
advance(20000);[...intervals.values()].forEach(f=>f());
assert.equal(root.children[0].children[0].children[1].children.at(-1).textContent,'1 minute 20 seconds');
send({id:'absolute',expiresAt:1000,serverTime:1001});assert.equal(root.children[0].children.length,0);
console.log('Absolute banner expiry, queued expiry and expired ID removal PASS');
