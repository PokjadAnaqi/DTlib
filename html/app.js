const $ = (selector) => document.querySelector(selector);
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'DTlib';
const post = (name, data = {}) =>
    fetch(`https://${resource}/${name}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data),
    });
const notifications = $('#notifications'),
    textui = $('#textui'),
    progress = $('#progress'),
    fill = $('#progress-fill'),
    modal = $('#modal'),
    menu = $('#menu'),
    input = $('#input');
let progressTimer = null,
    currentItems = [],
    menuCanClose = true;
function startProgress(progressData) {
    progress.classList.remove('hidden');
    $('#progress-label').textContent = progressData.label || 'Processing...';
    fill.style.transition = 'none';
    fill.style.width = '0%';
    requestAnimationFrame(() =>
        requestAnimationFrame(() => {
            fill.style.transition = `width ${Number(progressData.duration) || 1000}ms linear`;
            fill.style.width = '100%';
        }),
    );
    clearTimeout(progressTimer);
    progressTimer = setTimeout(() => progress.classList.add('hidden'), (Number(progressData.duration) || 1000) + 150);
}
function showTextUI(textData) {
    const title = $('#textui-title'),
        desc = $('#textui-text'),
        icon = $('#textui-icon'),
        opts = $('#textui-options');
    const titleText = textData.title || '';
    const descText = textData.description || textData.text || '';
    title.textContent = titleText;
    title.classList.toggle('hidden', !titleText);
    desc.textContent = descText;
    desc.classList.toggle('hidden', !descText);
    const iconText = textData.icon || '';
    renderIcon(icon, iconText);
    icon.style.color = textData.iconColor || '';
    icon.classList.toggle('hidden', !iconText);
    opts.innerHTML = '';
    const items = Array.isArray(textData.options) ? textData.options : [];
    items.forEach((item) => {
        const row = document.createElement('div');
        row.className = 'textui-option';
        const optionIcon = document.createElement('span');
        optionIcon.className = 'textui-option-icon';
        renderIcon(optionIcon, item.icon || '•');
        if (item.iconColor) optionIcon.style.color = item.iconColor;
        const optionLabel = document.createElement('span');
        optionLabel.className = 'textui-option-label';
        optionLabel.textContent = item.label || item.title || item.description || '';
        const keyBadge = document.createElement('span');
        keyBadge.className = 'textui-key';
        keyBadge.textContent = item.keybind || item.key || '';
        if (!keyBadge.textContent) keyBadge.style.visibility = 'hidden';
        row.append(optionIcon, optionLabel, keyBadge);
        opts.appendChild(row);
    });
    opts.classList.toggle('hidden', items.length === 0);
    textui.classList.remove('hidden');
}
function renderIcon(element, value) {
    element.replaceChildren();
    const tokens = String(value || '')
        .split(/\s+/)
        .filter((entry) => /^fa-[a-z0-9-]+$/.test(entry));
    if (tokens.length) {
        const icon = document.createElement('i');
        icon.className =
            (tokens.some((entry) => ['fa-solid', 'fa-regular', 'fa-brands'].includes(entry)) ? '' : 'fa-solid ') +
            tokens.join(' ');
        element.appendChild(icon);
    } else element.textContent = value || '';
}
function safeImage(value) {
    return typeof value === 'string' && /^(https:\/\/|nui:\/\/)/.test(value);
}
function openMenu(menuData) {
    currentItems = menuData.items || [];
    menuCanClose = menuData.canClose !== false;
    $('#menu-close').style.display = menuCanClose ? '' : 'none';
    $('#menu-title').textContent = menuData.title || 'DT MENU';
    $('#menu-subtitle').textContent = menuData.subtitle || '';
    const positions = {
        'top-left': ['flex-start', 'flex-start'],
        'top-right': ['flex-end', 'flex-start'],
        'center-left': ['flex-start', 'center'],
        'offcenter-left': ['flex-start', 'center'],
        'center-right': ['flex-end', 'center'],
        'offcenter-right': ['flex-end', 'center'],
        'bottom-left': ['flex-start', 'flex-end'],
        'bottom-right': ['flex-end', 'flex-end'],
    };
    const pos = positions[menuData.position] || ['center', 'center'];
    modal.style.justifyContent = pos[0];
    modal.style.alignItems = pos[1];
    const box = $('#menu-items');
    box.innerHTML = '';
    currentItems.forEach((item, index) => {
        const button = document.createElement('button');
        button.className = 'menu-item';
        const copy = document.createElement('span');
        copy.className = 'menu-copy';
        const title = document.createElement('strong');
        title.textContent = item.label || item.title || `Option ${index + 1}`;
        copy.appendChild(title);
        if (item.description) {
            const desc = document.createElement('small');
            desc.textContent = item.description;
            copy.appendChild(desc);
        }
        if (item.icon) {
            const icon = document.createElement('span');
            icon.className = 'menu-icon';
            renderIcon(icon, item.icon);
            icon.style.color = item.iconColor || '';
            button.appendChild(icon);
        }
        if (safeImage(item.image)) {
            const img = document.createElement('img');
            img.className = 'menu-image';
            img.src = item.image;
            img.alt = '';
            img.onerror = () => img.remove();
            button.appendChild(img);
        }
        if (item.metadata && typeof item.metadata === 'object') {
            Object.entries(item.metadata).forEach(([key, value]) => {
                const row = document.createElement('small');
                row.className = 'menu-metadata';
                row.textContent =
                    value && typeof value === 'object'
                        ? `${value.label || key}: ${value.value ?? ''}`
                        : Array.isArray(item.metadata)
                          ? String(value)
                          : `${key}: ${value}`;
                copy.appendChild(row);
            });
        }
        if (Number.isFinite(Number(item.progress)) && item.progress != null) {
            const meter = document.createElement('progress');
            meter.max = 100;
            meter.value = Math.max(0, Math.min(100, Number(item.progress)));
            meter.style.accentColor = item.progressColor || '';
            copy.appendChild(meter);
        }
        button.appendChild(copy);
        const right = document.createElement('span');
        right.className = 'menu-right';
        right.textContent = item.rightLabel || '';
        button.appendChild(right);
        button.disabled = !!(item.disabled || item.readOnly);
        button.onclick = () => {
            if (!item.disabled && !item.readOnly)
                post('menuSelect', {
                    index: index + 1,
                });
        };
        box.appendChild(button);
    });
    modal.classList.remove('hidden');
    menu.classList.remove('hidden');
    input.classList.add('hidden');
}
function closeMenu() {
    menu.classList.add('hidden');
    if (input.classList.contains('hidden')) modal.classList.add('hidden');
}
let inputCanCancel = true;
function openInput(inputData) {
    modal.style.justifyContent = 'center';
    modal.style.alignItems = 'center';
    inputCanCancel = inputData.cancel !== false;
    $('#input-cancel').textContent = inputData.cancelText || 'CANCEL';
    $('#input-cancel').style.display = inputCanCancel ? '' : 'none';
    $('#input-close').style.display = inputCanCancel ? '' : 'none';
    $('#input button[type=submit]').textContent = inputData.submitText || 'CONFIRM';
    $('#input-title').textContent = inputData.title || 'INPUT';
    $('#input-description').textContent = inputData.description || '';
    const box = $('#input-fields');
    box.innerHTML = '';
    (inputData.fields || []).forEach((field, index) => {
        const wrap = document.createElement('div');
        wrap.className = 'field';
        const id = `dt-field-${index}`;
        let control;
        if (field.type === 'select') {
            control = document.createElement('select');
            (field.options || []).forEach((option) => {
                const opt = document.createElement('option');
                opt.value = typeof option === 'object' ? option.value : option;
                opt.textContent = typeof option === 'object' ? option.label || option.value : option;
                control.appendChild(opt);
            });
        } else if (field.type === 'textarea') {
            control = document.createElement('textarea');
            control.rows = field.rows || 3;
        } else {
            control = document.createElement('input');
            control.type = field.type || 'text';
        }
        control.id = id;
        control.name = field.name || `field${index + 1}`;
        control.placeholder = field.placeholder || '';
        if (field.default !== undefined) control.value = field.default;
        control.required = !!field.required;
        wrap.innerHTML = `<label for="${id}">${escapeHtml(field.label || field.name || `Field ${index + 1}`)}</label>`;
        wrap.appendChild(control);
        box.appendChild(wrap);
    });
    modal.classList.remove('hidden');
    input.classList.remove('hidden');
    menu.classList.add('hidden');
}
function closeInput() {
    input.classList.add('hidden');
    if (menu.classList.contains('hidden')) modal.classList.add('hidden');
}
function escapeHtml(textValue) {
    return String(textValue ?? '').replace(
        /[&<>'"]/g,
        (character) =>
            ({
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                "'": '&#39;',
                '"': '&quot;',
            })[character],
    );
}
window.addEventListener('message', (event) => {
    const { action, data = {} } = event.data || {};
    if (action === 'notify') notify(data);
    if (action === 'notify:remove') DTNotifications.remove(data.id);
    if (action === 'textui:show') showTextUI(data);
    if (action === 'textui:hide') textui.classList.add('hidden');
    if (action === 'progress:start') startProgress(data);
    if (action === 'progress:stop') {
        clearTimeout(progressTimer);
        progress.classList.add('hidden');
    }
    if (action === 'menu:open') openMenu(data);
    if (action === 'menu:close') closeMenu();
    if (action === 'input:open') openInput(data);
    if (action === 'input:close') closeInput();
    if (action === 'ui:suspend') {
        DTNotifications.clear();
        textui.classList.add('hidden');
        progress.classList.add('hidden');
        modal.classList.add('hidden');
        menu.classList.add('hidden');
        input.classList.add('hidden');
    }
    if (action === 'ui:resume') {
    }
});
$('#menu-close').onclick = () => {
    if (menuCanClose) post('menuClose');
};
$('#input-close').onclick = () => post('inputCancel');
$('#input-cancel').onclick = () => post('inputCancel');
input.addEventListener('submit', (event) => {
    event.preventDefault();
    const values = {};
    new FormData(input).forEach((textValue, keyBadge) => (values[keyBadge] = textValue));
    post('inputSubmit', {
        values,
    });
});
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (!menu.classList.contains('hidden') && menuCanClose) post('menuClose');
        else if (!input.classList.contains('hidden') && inputCanCancel) post('inputCancel');
    }
});
