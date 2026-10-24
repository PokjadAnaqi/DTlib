import React,{useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import {post,image} from './bridge';
import '../style.css';
type Data=Record<string,any>;
export function Icon({value,color}:{value?:string;color?:string}){const tokens=String(value||'').split(/\s+/).filter(t=>/^fa-[a-z0-9-]+$/.test(t));return <span style={{color}}>{tokens.length?<i className={(tokens.some(t=>['fa-solid','fa-regular','fa-brands'].includes(t))?'':'fa-solid ')+tokens.join(' ')}/>:value}</span>}
export function App(){
 const [menu,M]=useState<Data|null>(null),[input,I]=useState<Data|null>(null),[text,T]=useState<Data|null>(null),[progress,P]=useState<Data|null>(null),[dialogue,D]=useState(false);
 useEffect(()=>{const handler=(e:MessageEvent)=>{const {action,data={}}=e.data||{};
  if(action==='notify')window.DTNotifications?.send(data);
  if(action==='notify:remove')window.DTNotifications?.remove(data.id);
  if(action==='menu:open'){M(data);I(null)}if(action==='menu:close')M(null);
  if(action==='input:open'){I(data);M(null)}if(action==='input:close')I(null);
  if(action==='textui:show')T(data);if(action==='textui:hide')T(null);
  if(action==='progress:start')P({...data,start:Date.now()});if(action==='progress:stop')P(null);
  if(action==='ui:suspend'){M(null);I(null);T(null);P(null);D(false);window.DTNotifications?.clear()}
  if(action==='ecosystem:dialogue'){D(data.type==='open');(document.getElementById('ecosystem-dialogue') as HTMLIFrameElement)?.contentWindow?.postMessage(data,'*')}
 };window.addEventListener('message',handler);return()=>window.removeEventListener('message',handler)},[]);
 useEffect(()=>{const key=(e:KeyboardEvent)=>{if(e.key!=='Escape')return;if(menu&&menu.canClose!==false)void post('menuClose');else if(input&&input.cancel!==false)void post('inputCancel')};window.addEventListener('keydown',key);return()=>window.removeEventListener('keydown',key)},[menu,input]);
 useEffect(()=>{if(!progress)return;const t=setTimeout(()=>P(null),(Number(progress.duration)||1000)+150);return()=>clearTimeout(t)},[progress]);
 const position=menu?.position||'center';const horizontal=position.includes('right')?'flex-end':position.includes('left')?'flex-start':'center';const vertical=position.includes('top')?'flex-start':position.includes('bottom')?'flex-end':'center';
 return <>
 {text&&<div id="textui"><div className="textui-head">{text.icon&&<span className="textui-icon"><Icon value={text.icon} color={text.iconColor}/></span>}<div className="textui-copy">{text.title&&<div className="textui-title">{text.title}</div>}<div className="textui-description">{text.description||text.text}</div></div></div>{text.options?.length>0&&<div className="textui-options">{text.options.map((o:Data,i:number)=><div className="textui-option" key={i}><span className="textui-option-icon"><Icon value={o.icon} color={o.iconColor}/></span><span className="textui-option-label">{o.label||o.title||o.description}</span><span className="textui-key">{o.keybind||o.key}</span></div>)}</div>}</div>}
 {progress&&<div id="progress" key={progress.start}><div className="progress-label">{progress.label||'Processing...'}</div><div className="progress-track"><div id="progress-fill" style={{width:'100%',animation:`dt-progress ${Number(progress.duration)||1000}ms linear`}}/></div></div>}
 {(menu||input)&&<div id="modal" style={{justifyContent:input?'center':horizontal,alignItems:input?'center':vertical}}>
 {menu&&<div id="menu" className="panel"><div className="panel-head"><div><div className="eyebrow">DT ECOSYSTEM</div><h1>{menu.title||'DT MENU'}</h1><p>{menu.subtitle}</p></div>{menu.canClose!==false&&<button className="close" onClick={()=>void post('menuClose')}>×</button>}</div><div id="menu-items">{(menu.items||[]).map((o:Data,i:number)=><button className="menu-item" key={i} disabled={o.disabled||o.readOnly} onClick={()=>void post('menuSelect',{index:i+1})}>{o.icon&&<span className="menu-icon"><Icon value={o.icon} color={o.iconColor}/></span>}{image(o.image)&&<img className="menu-image" src={o.image} alt="" onError={e=>e.currentTarget.style.display='none'}/>}<span className="menu-copy"><strong>{o.label||o.title||`Option ${i+1}`}</strong>{o.description&&<small>{o.description}</small>}{o.metadata&&Object.entries(o.metadata).map(([k,v]:[string,any])=><small className="menu-metadata" key={k}>{typeof v==='object'&&v?`${v.label||k}: ${v.value??''}`:Array.isArray(o.metadata)?String(v):`${k}: ${v}`}</small>)}{o.progress!=null&&Number.isFinite(Number(o.progress))&&<progress max={100} value={Math.max(0,Math.min(100,Number(o.progress)))} style={{accentColor:o.progressColor}}/>}</span><span className="menu-right">{o.rightLabel}</span></button>)}</div></div>}
 {input&&<form id="input" className="panel" key={JSON.stringify(input)} onSubmit={e=>{e.preventDefault();void post('inputSubmit',{values:Object.fromEntries(new FormData(e.currentTarget))})}}><div className="panel-head"><div><div className="eyebrow">DT ECOSYSTEM</div><h1>{input.title||'INPUT'}</h1><p>{input.description}</p></div>{input.cancel!==false&&<button type="button" className="close" onClick={()=>void post('inputCancel')}>×</button>}</div><div id="input-fields">{(input.fields||[]).map((f:Data,i:number)=>{const props={id:`field-${i}`,name:f.name||`field${i+1}`,defaultValue:f.default,required:!!f.required,placeholder:f.placeholder,min:f.min,max:f.max,step:f.step};return <div className="field" key={i}><label htmlFor={props.id}>{f.label||f.name||`Field ${i+1}`}</label>{f.type==='select'?<select {...props}>{(f.options||[]).map((o:any,j:number)=><option key={j} value={typeof o==='object'?o.value:o}>{typeof o==='object'?o.label||o.value:o}</option>)}</select>:f.type==='textarea'?<textarea {...props} rows={f.rows||3}/>:<input {...props} type={f.type||'text'}/>}</div>})}</div><div className="input-actions">{input.cancel!==false&&<button type="button" onClick={()=>void post('inputCancel')}>{input.cancelText||'CANCEL'}</button>}<button type="submit" className="primary">{input.submitText||'CONFIRM'}</button></div></form>}
 </div>}
 <iframe id="ecosystem-dialogue" title="Dialogue" src="../dialogue/dist/index.html" style={{position:'fixed',inset:0,width:'100%',height:'100%',border:0,display:dialogue?'block':'none',background:'transparent',zIndex:90}}/>
 </>;
}
const root=document.getElementById('root');if(root)createRoot(root).render(<App/>);
