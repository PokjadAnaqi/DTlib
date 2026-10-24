import React,{useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import './interact.css';
import {post} from './bridge';
void post('interactReady');
function App(){const[d,S]=useState<any>(null);useEffect(()=>{const h=(e:MessageEvent)=>{if(e.data?.action==='interact')S(e.data.data)};window.addEventListener('message',h);void post('interactReady');return()=>window.removeEventListener('message',h)},[]);return d?.options?.length?<div className="interaction"><header>DT INTERACTION</header>{d.options.map((o:any,i:number)=><div key={i} className={'option '+(i+1===d.selected?'selected':'')}><kbd>{i+1===d.selected?d.key:'·'}</kbd><span>{o.label}</span></div>)}{d.options.length>1&&<footer>↑ ↓ SELECT · {d.key} CONFIRM</footer>}</div>:null}
createRoot(document.getElementById('root')!).render(<App/>);
