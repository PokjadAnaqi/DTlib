const fs=require('fs'),vm=require('vm'),assert=require('assert');
class Element{
 constructor(){this.children=[];this.style={};this.hidden=false;this.classes=new Set(['hidden']);this.classList={add:x=>this.classes.add(x),remove:x=>this.classes.delete(x),contains:x=>this.classes.has(x),toggle:(x,on)=>on?this.classes.add(x):this.classes.delete(x)};}
 appendChild(x){this.children.push(x);return x;}
 append(...x){x.forEach(y=>this.appendChild(y));}
 replaceChildren(){this.children=[];}
 set innerHTML(value){assert(value==='');this.children=[];}
 addEventListener(){}
 remove(){this.removed=true;}
}
const elements=new Map(),get=id=>{if(!elements.has(id))elements.set(id,new Element());return elements.get(id);};
const posts=[];let keydown;
const ctx={document:{querySelector:get,createElement:()=>new Element(),addEventListener:(n,fn)=>{if(n==='keydown')keydown=fn;}},window:{addEventListener(){}},fetch:(url)=>posts.push(url),setTimeout(){},clearTimeout(){},requestAnimationFrame:f=>f()};
vm.createContext(ctx);vm.runInContext(fs.readFileSync(__dirname+'/../html/app.js','utf8'),ctx);
ctx.openMenu({canClose:false,position:'offcenter-right',items:[{label:'Guide',image:'nui://DTlib/image.png',icon:'fa-solid fa-book',metadata:[{label:'Level',value:3}],progress:50,readOnly:true}]});
assert.equal(get('#modal').style.justifyContent,'flex-end');assert.equal(get('#menu-close').style.display,'none');
const row=get('#menu-items').children[0];assert(row.disabled);assert.equal(row.children[0].children[0].className,'fa-solid fa-book');
assert.equal(row.children[1].src,'nui://DTlib/image.png');assert.equal(row.children[2].children[1].textContent,'Level: 3');assert.equal(row.children[2].children[2].value,50);
keydown({key:'Escape'});assert.equal(posts.length,0);row.onclick();assert.equal(posts.length,0);
ctx.openMenu({items:[{label:'Select',image:'javascript:bad'}]});keydown({key:'Escape'});assert(posts[0].endsWith('/menuClose'));assert.equal(get('#menu-items').children[0].children.length,2);
ctx.showTextUI({icon:'fa-solid fa-temperature-half',text:'Temperature',options:[{icon:'fa-solid fa-key',label:'Use'}]});assert.equal(get('#textui-icon').children[0].className,'fa-solid fa-temperature-half');
console.log('Native menu positioning, icons, safe images, metadata, progress, readOnly/canClose and TextUI icons PASS');
