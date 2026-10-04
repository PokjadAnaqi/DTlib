const marker=document.getElementById('waypoint');
let readyPosted=false;
async function postReady(){
 if(readyPosted)return;
 try{
  await fetch('https://DTlib/dtlib_waypoint_ready',{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:'{}'});
  readyPosted=true;
 }catch(_){/* Rendering does not depend on this diagnostic callback. */}
}
const label=document.getElementById('label');
const subtitle=document.getElementById('subtitle');
const distance=document.getElementById('distance');
const distanceWrap=document.getElementById('distance-wrap');
const icon=document.getElementById('icon');
const image=document.getElementById('image');
const shell=document.getElementById('icon-shell');

const safeType=value=>['objective','checkpoint','small','danger'].includes(String(value))?String(value):'objective';
const hexToRgb=hex=>{const value=String(hex||'#9db34f').replace('#','');if(!/^[0-9a-f]{6}$/i.test(value))return '157,179,79';return `${parseInt(value.slice(0,2),16)},${parseInt(value.slice(2,4),16)},${parseInt(value.slice(4,6),16)}`};
const isImage=value=>typeof value==='string'&&(/^(https?:|nui:|data:|https:\/\/cfx-nui-)/i.test(value)||/\.(png|jpe?g|webp|gif|svg)(\?|$)/i.test(value));

function reset(){
 marker.className='waypoint objective';
 marker.style.setProperty('--accent','#9db34f');marker.style.setProperty('--accent-rgb','157,179,79');
 label.textContent='OBJECTIVE';subtitle.textContent='DT NAVIGATION';distance.textContent='0';distanceWrap.style.display='flex';
 icon.className='fa-solid fa-location-dot';icon.style.color='';icon.style.display='block';image.style.display='none';image.removeAttribute('src');shell.classList.remove('has-image');
}
function configure(data={}){
 const type=safeType(data.type);marker.className=`waypoint ${type}${data.pulse?' pulse':''}`;
 const color=data.color||'#9db34f';marker.style.setProperty('--accent',color);marker.style.setProperty('--accent-rgb',hexToRgb(color));
 label.textContent=String(data.label||'OBJECTIVE').toUpperCase();subtitle.textContent=String(data.subtitle||'DT NAVIGATION').toUpperCase();
 distanceWrap.style.display=data.displayDistance===false?'none':'flex';
 if(data.image&&isImage(data.image)){image.src=data.image;image.style.display='block';icon.style.display='none';shell.classList.add('has-image');}
 else if(data.icon&&isImage(data.icon)){image.src=data.icon;image.style.display='block';icon.style.display='none';shell.classList.add('has-image');}
 else{image.style.display='none';image.removeAttribute('src');icon.style.display='block';icon.className=String(data.icon||'fa-solid fa-location-dot');icon.style.color=data.iconColor||'';shell.classList.remove('has-image');}
}
window.addEventListener('message',event=>{const message=event.data||{};if(message.action==='dtlib:init')postReady();else if(message.action==='configure')configure(message.data||{});else if(message.action==='distance')distance.textContent=String(Math.max(0,Number(message.value)||0));else if(message.action==='reset')reset();});
window.addEventListener('DOMContentLoaded',postReady);
reset();
