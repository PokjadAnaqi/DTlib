const ecosystemFrame=document.getElementById('ecosystem-dialogue');
window.addEventListener('message',event=>{
 const {action,data={}}=event.data||{};
 if(action==='ecosystem:dialogue'){
  if(data.type==='open')ecosystemFrame.style.display='block';
  if(data.type==='close')ecosystemFrame.style.display='none';
  ecosystemFrame.contentWindow.postMessage(data,'*');
 }
 if(action==='ui:suspend')ecosystemFrame.style.display='none';
});
