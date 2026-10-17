const $=s=>document.querySelector(s);const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'DTlib';const post=(name,data={})=>fetch(`https://${resource}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});
const notifications=$('#notifications'),textui=$('#textui'),progress=$('#progress'),fill=$('#progress-fill'),modal=$('#modal'),menu=$('#menu'),input=$('#input');let progressTimer=null,currentItems=[],menuCanClose=true;

function startProgress(d){progress.classList.remove('hidden');$('#progress-label').textContent=d.label||'Processing...';fill.style.transition='none';fill.style.width='0%';requestAnimationFrame(()=>requestAnimationFrame(()=>{fill.style.transition=`width ${Number(d.duration)||1000}ms linear`;fill.style.width='100%'}));clearTimeout(progressTimer);progressTimer=setTimeout(()=>progress.classList.add('hidden'),(Number(d.duration)||1000)+150)}
function showTextUI(d){
    const title=$('#textui-title'),desc=$('#textui-text'),icon=$('#textui-icon'),opts=$('#textui-options');
    const titleText=d.title||'';const descText=d.description||d.text||'';
    title.textContent=titleText;title.classList.toggle('hidden',!titleText);
    desc.textContent=descText;desc.classList.toggle('hidden',!descText);
    const iconText=d.icon||'';renderIcon(icon,iconText);icon.style.color=d.iconColor||'';icon.classList.toggle('hidden',!iconText);
    opts.innerHTML='';const items=Array.isArray(d.options)?d.options:[];
    items.forEach(item=>{const row=document.createElement('div');row.className='textui-option';
        const i=document.createElement('span');i.className='textui-option-icon';renderIcon(i,item.icon||'•');if(item.iconColor)i.style.color=item.iconColor;
        const l=document.createElement('span');l.className='textui-option-label';l.textContent=item.label||item.title||item.description||'';
        const k=document.createElement('span');k.className='textui-key';k.textContent=item.keybind||item.key||'';if(!k.textContent)k.style.visibility='hidden';
        row.append(i,l,k);opts.appendChild(row)});
    opts.classList.toggle('hidden',items.length===0);textui.classList.remove('hidden');
}
function renderIcon(element,value){
    element.replaceChildren();
    const tokens=String(value||'').split(/\s+/).filter(x=>/^fa-[a-z0-9-]+$/.test(x));
    if(tokens.length){const icon=document.createElement('i');icon.className=(tokens.some(x=>['fa-solid','fa-regular','fa-brands'].includes(x))?'':'fa-solid ')+tokens.join(' ');element.appendChild(icon);}
    else element.textContent=value||'';
}
function safeImage(value){return typeof value==='string'&&/^(https:\/\/|nui:\/\/)/.test(value);}
function openMenu(d){
    currentItems=d.items||[];menuCanClose=d.canClose!==false;
    $('#menu-close').style.display=menuCanClose?'':'none';
    $('#menu-title').textContent=d.title||'DT MENU';$('#menu-subtitle').textContent=d.subtitle||'';
    const positions={'top-left':['flex-start','flex-start'],'top-right':['flex-end','flex-start'],'center-left':['flex-start','center'],'offcenter-left':['flex-start','center'],'center-right':['flex-end','center'],'offcenter-right':['flex-end','center'],'bottom-left':['flex-start','flex-end'],'bottom-right':['flex-end','flex-end']};
    const pos=positions[d.position]||['center','center'];modal.style.justifyContent=pos[0];modal.style.alignItems=pos[1];
    const box=$('#menu-items');box.innerHTML='';
    currentItems.forEach((item,index)=>{
        const b=document.createElement('button');b.className='menu-item';
        const copy=document.createElement('span');copy.className='menu-copy';
        const title=document.createElement('strong');title.textContent=item.label||item.title||`Option ${index+1}`;copy.appendChild(title);
        if(item.description){const desc=document.createElement('small');desc.textContent=item.description;copy.appendChild(desc);}
        if(item.icon){const icon=document.createElement('span');icon.className='menu-icon';renderIcon(icon,item.icon);icon.style.color=item.iconColor||'';b.appendChild(icon);}
        if(safeImage(item.image)){const img=document.createElement('img');img.className='menu-image';img.src=item.image;img.alt='';img.onerror=()=>img.remove();b.appendChild(img);}
        if(item.metadata&&typeof item.metadata==='object'){
            Object.entries(item.metadata).forEach(([key,value])=>{const row=document.createElement('small');row.className='menu-metadata';row.textContent=value&&typeof value==='object'?`${value.label||key}: ${value.value??''}`:Array.isArray(item.metadata)?String(value):`${key}: ${value}`;copy.appendChild(row);});
        }
        if(Number.isFinite(Number(item.progress))&&item.progress!=null){const meter=document.createElement('progress');meter.max=100;meter.value=Math.max(0,Math.min(100,Number(item.progress)));meter.style.accentColor=item.progressColor||'';copy.appendChild(meter);}
        b.appendChild(copy);const right=document.createElement('span');right.className='menu-right';right.textContent=item.rightLabel||'';b.appendChild(right);
        b.disabled=!!(item.disabled||item.readOnly);b.onclick=()=>{if(!item.disabled&&!item.readOnly)post('menuSelect',{index:index+1});};box.appendChild(b);
    });
    modal.classList.remove('hidden');menu.classList.remove('hidden');input.classList.add('hidden');
}
function closeMenu(){menu.classList.add('hidden');if(input.classList.contains('hidden'))modal.classList.add('hidden')}
let inputCanCancel=true;
function openInput(d){modal.style.justifyContent="center";modal.style.alignItems="center";inputCanCancel=d.cancel!==false;$('#input-cancel').textContent=d.cancelText||'CANCEL';$('#input-cancel').style.display=inputCanCancel?'':'none';$('#input-close').style.display=inputCanCancel?'':'none';$('#input button[type=submit]').textContent=d.submitText||'CONFIRM';$('#input-title').textContent=d.title||'INPUT';$('#input-description').textContent=d.description||'';const box=$('#input-fields');box.innerHTML='';(d.fields||[]).forEach((f,index)=>{const wrap=document.createElement('div');wrap.className='field';const id=`dt-field-${index}`;let control;if(f.type==='select'){control=document.createElement('select');(f.options||[]).forEach(o=>{const opt=document.createElement('option');opt.value=typeof o==='object'?o.value:o;opt.textContent=typeof o==='object'?(o.label||o.value):o;control.appendChild(opt)})}else if(f.type==='textarea'){control=document.createElement('textarea');control.rows=f.rows||3}else{control=document.createElement('input');control.type=f.type||'text'}control.id=id;control.name=f.name||`field${index+1}`;control.placeholder=f.placeholder||'';if(f.default!==undefined)control.value=f.default;control.required=!!f.required;wrap.innerHTML=`<label for="${id}">${escapeHtml(f.label||f.name||`Field ${index+1}`)}</label>`;wrap.appendChild(control);box.appendChild(wrap)});modal.classList.remove('hidden');input.classList.remove('hidden');menu.classList.add('hidden')}
function closeInput(){input.classList.add('hidden');if(menu.classList.contains('hidden'))modal.classList.add('hidden')}
function escapeHtml(v){return String(v??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]))}
window.addEventListener('message',e=>{const{action,data={}}=e.data||{};if(action==='notify')notify(data);if(action==='notify:remove')DTNotifications.remove(data.id);if(action==='textui:show')showTextUI(data);if(action==='textui:hide')textui.classList.add('hidden');if(action==='progress:start')startProgress(data);if(action==='progress:stop'){clearTimeout(progressTimer);progress.classList.add('hidden')}if(action==='menu:open')openMenu(data);if(action==='menu:close')closeMenu();if(action==='input:open')openInput(data);if(action==='input:close')closeInput();if(action==='ui:suspend'){DTNotifications.clear();textui.classList.add('hidden');progress.classList.add('hidden');modal.classList.add('hidden');menu.classList.add('hidden');input.classList.add('hidden')}if(action==='ui:resume'){} });
$('#menu-close').onclick=()=>{if(menuCanClose)post('menuClose')};$('#input-close').onclick=()=>post('inputCancel');$('#input-cancel').onclick=()=>post('inputCancel');input.addEventListener('submit',e=>{e.preventDefault();const values={};new FormData(input).forEach((v,k)=>values[k]=v);post('inputSubmit',{values})});document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(!menu.classList.contains('hidden')&&menuCanClose)post('menuClose');else if(!input.classList.contains('hidden')&&inputCanCancel)post('inputCancel')}});
