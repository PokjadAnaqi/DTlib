declare global {interface Window {GetParentResourceName?:()=>string; DTNotifications?:{send:(d:any)=>void;remove:(id:any)=>void;clear:()=>void}}}
export const post=(name:string,data:unknown={})=>fetch(`https://${window.GetParentResourceName?.()||'DTlib'}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});
export const image=(v:unknown):v is string=>typeof v==='string'&&/^(https:\/\/|nui:\/\/)/.test(v);
