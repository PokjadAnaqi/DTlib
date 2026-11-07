/* Delta native notification renderer. */
const DTNotifications = (() => {
    const root = document.querySelector('#notifications');
    const lanes = new Map();
    const types = new Set(['info', 'success', 'warning', 'error']);
    const positions = new Set([
        'top-left',
        'top',
        'top-right',
        'center-left',
        'center-right',
        'bottom-left',
        'bottom',
        'bottom-right',
    ]);
    const icons = {
        info: 'fa-circle-info',
        success: 'fa-circle-check',
        warning: 'fa-triangle-exclamation',
        error: 'fa-circle-exclamation',
    };
    const clean = (notificationData) => ({
        ...notificationData,
        title: String(notificationData.title || ''),
        subtitle: String(notificationData.subtitle || ''),
        description: String(notificationData.message ?? notificationData.description ?? ''),
        type: types.has(notificationData.type) ? notificationData.type : 'info',
        position: positions.has(notificationData.position) ? notificationData.position : 'top-right',
        duration: Math.max(250, Math.min(86400000, Number(notificationData.duration) || 4500)),
    });
    const key = (notificationData) =>
        JSON.stringify([
            notificationData.layout,
            notificationData.title,
            notificationData.subtitle,
            notificationData.description,
            notificationData.type,
            notificationData.icon,
            notificationData.image,
            notificationData.progress,
        ]);
    function lane(position) {
        if (!lanes.has(position)) {
            const element = document.createElement('div');
            element.className = `notify-lane ${position}`;
            root.appendChild(element);
            lanes.set(position, {
                el: element,
                active: [],
                queue: [],
            });
        }
        return lanes.get(position);
    }
    function text(tag, cls, value) {
        const element = document.createElement(tag);
        element.className = cls;
        element.textContent = value;
        return element;
    }
    function render(card) {
        const notificationData = card.data,
            element = card.el;
        element.replaceChildren();
        element.className = `notify ${notificationData.type}${notificationData.layout === 'banner' ? ' notify-banner' : ''}`;
        element.setAttribute('role', 'status');
        const picture = document.createElement('div');
        picture.className = 'notify-picture';
        const icon = document.createElement('i');
        const tokens = String(notificationData.icon || '')
            .split(/\s+/)
            .filter((activeCard) => /^fa-[a-z0-9-]+$/.test(activeCard));
        icon.className = tokens.length
            ? (tokens.some((activeCard) => ['fa-solid', 'fa-regular', 'fa-brands'].includes(activeCard))
                  ? ''
                  : 'fa-solid ') + tokens.join(' ')
            : `fa-solid ${icons[notificationData.type]}`;
        picture.appendChild(icon);
        if (
            typeof notificationData.image === 'string' &&
            /^(https:\/\/|nui:\/\/|(?:\.?\.?\/)?[a-zA-Z0-9_-]+\/)/.test(notificationData.image)
        ) {
            const img = document.createElement('img');
            img.alt = '';
            img.src = notificationData.image;
            img.onerror = () => {
                img.remove();
                icon.hidden = false;
            };
            icon.hidden = true;
            picture.appendChild(img);
        }
        const copy = document.createElement('div');
        copy.className = 'notify-copy';
        if (notificationData.title) copy.appendChild(text('div', 'notify-title', notificationData.title));
        if (notificationData.subtitle) copy.appendChild(text('div', 'notify-subtitle', notificationData.subtitle));
        if (notificationData.description) copy.appendChild(text('div', 'notify-desc', notificationData.description));
        element.append(picture, copy);
        if (card.count > 1) element.appendChild(text('span', 'notify-count', `×${card.count}`));
        if (
            notificationData.layout === 'banner' &&
            notificationData.countdown !== false &&
            !notificationData.persistent
        ) {
            const remaining = text('div', 'notify-remaining', '');
            copy.appendChild(remaining);
            card.remaining = remaining;
        } else card.remaining = null;
        if (
            !notificationData.persistent &&
            notificationData.progress !== false &&
            (notificationData.layout === 'banner' || notificationData.showDuration || notificationData.progress)
        ) {
            const bar = document.createElement('div');
            bar.className = 'notify-lifetime';
            bar.style.animationDuration = `${notificationData.duration}ms`;
            element.appendChild(bar);
        }
    }
    function arm(notificationLane, card) {
        if (card.data.deadline != null) card.data.duration = Math.max(0, card.data.deadline - Date.now());
        clearTimeout(card.timer);
        clearInterval(card.interval);
        render(card);
        if (card.data.persistent) return;
        const end = Date.now() + card.data.duration;
        const update = () => {
            if (card.remaining) {
                const seconds = Math.max(0, Math.ceil((end - Date.now()) / 1000));
                const mins = Math.floor(seconds / 60);
                card.remaining.textContent = `${mins} ${mins === 1 ? 'minute' : 'minutes'} ${seconds % 60} ${seconds % 60 === 1 ? 'second' : 'seconds'}`;
            }
        };
        update();
        if (card.remaining) card.interval = setInterval(update, 1000);
        card.timer = setTimeout(() => {
            clearInterval(card.interval);
            card.el.classList.add('notify-leaving');
            card.timer = setTimeout(() => {
                card.el.remove();
                notificationLane.active = notificationLane.active.filter((activeCard) => activeCard !== card);
                pump(notificationLane);
            }, 180);
        }, card.data.duration);
    }
    function pump(notificationLane) {
        while (notificationLane.queue.length && notificationLane.active.length < notificationLane.limit) {
            const card = notificationLane.queue.shift();
            if (card.data.deadline != null && card.data.deadline <= Date.now()) continue;
            card.el = document.createElement('div');
            notificationLane.el.appendChild(card.el);
            notificationLane.active.push(card);
            arm(notificationLane, card);
        }
    }
    function send(raw) {
        const notificationData = clean(raw);
        if (Number.isFinite(Number(raw.expiresAt)) && Number(raw.expiresAt) > 0) {
            const serverTime = Number(raw.serverTime);
            notificationData.deadline =
                serverTime > 0
                    ? Date.now() + (Number(raw.expiresAt) - serverTime) * 1000
                    : Number(raw.expiresAt) * 1000;
            notificationData.persistent = false;
            if (notificationData.deadline <= Date.now()) {
                if (notificationData.id != null) remove(notificationData.id);
                return;
            }
        }
        const notificationLane = lane(notificationData.position);
        notificationLane.limit = Math.max(1, Math.min(8, Number(notificationData.maxVisible) || 5));
        const match = notificationLane.active
            .concat(notificationLane.queue)
            .find((queuedCard) =>
                notificationData.id != null
                    ? queuedCard.data.id === notificationData.id
                    : notificationData.stack !== false &&
                      queuedCard.data.stack !== false &&
                      queuedCard.data.id == null &&
                      key(queuedCard.data) === key(notificationData),
            );
        if (match) {
            match.data = notificationData;
            if (notificationData.id == null) match.count++;
            if (match.el) arm(notificationLane, match);
            return;
        }
        if (notificationLane.queue.length >= 50) notificationLane.queue.shift();
        notificationLane.queue.push({
            data: notificationData,
            count: 1,
            el: null,
            timer: null,
        });
        pump(notificationLane);
    }
    function remove(id) {
        for (const notificationLane of lanes.values()) {
            notificationLane.queue = notificationLane.queue.filter((queuedCard) => queuedCard.data.id !== id);
            for (const queuedCard of notificationLane.active.filter((c) => c.data.id === id)) {
                clearTimeout(queuedCard.timer);
                clearInterval(queuedCard.interval);
                queuedCard.el.remove();
                notificationLane.active = notificationLane.active.filter((activeCard) => activeCard !== queuedCard);
            }
            pump(notificationLane);
        }
    }
    function clear() {
        for (const notificationLane of lanes.values())
            for (const queuedCard of notificationLane.active) {
                clearTimeout(queuedCard.timer);
                clearInterval(queuedCard.interval);
            }
        lanes.clear();
        root.replaceChildren();
    }
    return {
        send,
        clear,
        remove,
    };
})();
function notify(data) {
    DTNotifications.send(data);
}
if (typeof window !== 'undefined') window.DTNotifications = DTNotifications;
