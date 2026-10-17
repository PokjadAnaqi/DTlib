/* Delta native notification renderer. */
const DTNotifications = (() => {
    const root = document.querySelector('#notifications');
    const lanes = new Map();
    const types = new Set(['info', 'success', 'warning', 'error']);
    const positions = new Set(['top-left', 'top', 'top-right', 'center-left', 'center-right', 'bottom-left', 'bottom', 'bottom-right']);
    const icons = {info:'fa-circle-info', success:'fa-circle-check', warning:'fa-triangle-exclamation', error:'fa-circle-exclamation'};
    const clean = d => ({...d, title:String(d.title || ''), subtitle:String(d.subtitle || ''), description:String(d.message ?? d.description ?? ''), type:types.has(d.type) ? d.type : 'info', position:positions.has(d.position) ? d.position : 'top-right', duration:Math.max(250, Math.min(86400000, Number(d.duration) || 4500))});
    const key = d => JSON.stringify([d.layout,d.title,d.subtitle,d.description,d.type,d.icon,d.image,d.progress]);
    function lane(position) {
        if (!lanes.has(position)) {
            const el = document.createElement('div'); el.className = `notify-lane ${position}`;
            root.appendChild(el); lanes.set(position, {el, active:[], queue:[]});
        }
        return lanes.get(position);
    }
    function text(tag, cls, value) {
        const el = document.createElement(tag); el.className = cls; el.textContent = value; return el;
    }
    function render(card) {
        const d=card.data, el=card.el; el.replaceChildren();
        el.className = `notify ${d.type}${d.layout === 'banner' ? ' notify-banner' : ''}`;
        el.setAttribute('role','status');
        const picture=document.createElement('div'); picture.className='notify-picture';
        const icon=document.createElement('i');
        const tokens=String(d.icon || '').split(/\s+/).filter(x=>/^fa-[a-z0-9-]+$/.test(x));
        icon.className=tokens.length ? (tokens.some(x=>['fa-solid','fa-regular','fa-brands'].includes(x)) ? '' : 'fa-solid ') + tokens.join(' ') : `fa-solid ${icons[d.type]}`;
        picture.appendChild(icon);
        if (typeof d.image==='string' && /^(https:\/\/|nui:\/\/|(?:\.?\.?\/)?[a-zA-Z0-9_-]+\/)/.test(d.image)) {
            const img=document.createElement('img'); img.alt=''; img.src=d.image;
            img.onerror=()=>{img.remove();icon.hidden=false;};icon.hidden=true;picture.appendChild(img);
        }
        const copy=document.createElement('div'); copy.className='notify-copy';
        if(d.title)copy.appendChild(text('div','notify-title',d.title));
        if(d.subtitle)copy.appendChild(text('div','notify-subtitle',d.subtitle));
        if(d.description)copy.appendChild(text('div','notify-desc',d.description));
        el.append(picture,copy);
        if(card.count>1)el.appendChild(text('span','notify-count',`×${card.count}`));
        if(d.layout==='banner' && d.countdown!==false && !d.persistent) {
            const remaining=text('div','notify-remaining','');copy.appendChild(remaining);card.remaining=remaining;
        } else card.remaining=null;
        if(!d.persistent && d.progress !== false && (d.layout==='banner' || d.showDuration || d.progress)) {
            const bar=document.createElement('div');bar.className='notify-lifetime';bar.style.animationDuration=`${d.duration}ms`;el.appendChild(bar);
        }
    }
    function arm(l,card) {
        if(card.data.deadline!=null)card.data.duration=Math.max(0,card.data.deadline-Date.now());
        clearTimeout(card.timer);clearInterval(card.interval);render(card);
        if(card.data.persistent)return;
        const end=Date.now()+card.data.duration;
        const update=()=>{if(card.remaining){const seconds=Math.max(0,Math.ceil((end-Date.now())/1000));const mins=Math.floor(seconds/60);card.remaining.textContent=`${mins} ${mins===1 ? 'minute' : 'minutes'} ${seconds%60} ${seconds%60===1 ? 'second' : 'seconds'}`;}};
        update();if(card.remaining)card.interval=setInterval(update,1000);
        card.timer=setTimeout(()=>{
            clearInterval(card.interval);card.el.classList.add('notify-leaving');
            card.timer=setTimeout(()=>{card.el.remove();l.active=l.active.filter(x=>x!==card);pump(l);},180);
        },card.data.duration);
    }
    function pump(l) {
        while(l.queue.length && l.active.length < l.limit) {
            const card=l.queue.shift();if(card.data.deadline!=null&&card.data.deadline<=Date.now())continue;card.el=document.createElement('div');l.el.appendChild(card.el);l.active.push(card);arm(l,card);
        }
    }
    function send(raw) {
        const d=clean(raw);
        if(Number.isFinite(Number(raw.expiresAt))&&Number(raw.expiresAt)>0){
            const serverTime=Number(raw.serverTime);
            d.deadline=serverTime>0?Date.now()+(Number(raw.expiresAt)-serverTime)*1000:Number(raw.expiresAt)*1000;
            d.persistent=false;
            if(d.deadline<=Date.now()){if(d.id!=null)remove(d.id);return;}
        }
        const l=lane(d.position);
        l.limit=Math.max(1,Math.min(8,Number(d.maxVisible)||5));
        const match=l.active.concat(l.queue).find(c=>d.id!=null ? c.data.id===d.id : d.stack!==false && c.data.stack!==false && c.data.id==null && key(c.data)===key(d));
        if(match) {match.data=d;if(d.id==null)match.count++;if(match.el)arm(l,match);return;}
        if(l.queue.length>=50)l.queue.shift();
        l.queue.push({data:d,count:1,el:null,timer:null});pump(l);
    }
    function remove(id) {
        for(const l of lanes.values()){l.queue=l.queue.filter(c=>c.data.id!==id);for(const c of l.active.filter(c=>c.data.id===id)){clearTimeout(c.timer);clearInterval(c.interval);c.el.remove();l.active=l.active.filter(x=>x!==c);}pump(l);}
    }
    function clear() {
        for(const l of lanes.values())for(const c of l.active){clearTimeout(c.timer);clearInterval(c.interval);}
        lanes.clear();root.replaceChildren();
    }
    return {send,clear,remove};
})();
function notify(data) { DTNotifications.send(data); }
