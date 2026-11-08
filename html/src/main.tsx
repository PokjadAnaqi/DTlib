import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { post, image } from './bridge';
import '../api69.css';
import '../style.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
type Data = Record<string, any>;
export function Icon({ value, color }: { value?: string; color?: string }) {
    const tokens = String(value || '')
        .split(/\s+/)
        .filter((token) => /^fa-[a-z0-9-]+$/.test(token));
    return (
        <span
            style={{
                color,
            }}
        >
            {tokens.length ? (
                <i
                    className={
                        (tokens.some((token) => ['fa-solid', 'fa-regular', 'fa-brands'].includes(token))
                            ? ''
                            : 'fa-solid ') + tokens.join(' ')
                    }
                />
            ) : (
                value
            )}
        </span>
    );
}
export function App() {
    const [menu, setMenu] = useState<Data | null>(null);
    const [input, setInput] = useState<Data | null>(null);
    const [text, setText] = useState<Data | null>(null);
    const [progress, setProgress] = useState<Data | null>(null);
    const [dialogue, setDialogue] = useState(false);

    useEffect(() => {
        const handler = (event: MessageEvent) => {
            const { action, data = {} } = event.data || {};
            if (action === 'notify') window.DTNotifications?.send(data);
            if (action === 'notify:remove') window.DTNotifications?.remove(data.id);
            if (action === 'menu:open') {
                setMenu(data);
                setInput(null);
            }
            if (action === 'menu:close') setMenu(null);
            if (action === 'input:open') {
                setInput(data);
                setMenu(null);
            }
            if (action === 'input:close') setInput(null);
            if (action === 'textui:show') setText(data);
            if (action === 'textui:hide') setText(null);
            if (action === 'progress:start')
                setProgress({
                    ...data,
                    start: Date.now(),
                });
            if (action === 'progress:stop') setProgress(null);
            if (action === 'ui:suspend') {
                setMenu(null);
                setInput(null);
                setText(null);
                setProgress(null);
                setDialogue(false);
                window.DTNotifications?.clear();
            }
            if (action === 'ecosystem:dialogue') {
                setDialogue(data.type === 'open');
                (document.getElementById('ecosystem-dialogue') as HTMLIFrameElement)?.contentWindow?.postMessage(
                    data,
                    '*',
                );
            }
        };
        window.addEventListener('message', handler);
        return () => window.removeEventListener('message', handler);
    }, []);
    useEffect(() => {
        const key = (event: KeyboardEvent) => {
            if (event.key !== 'Escape') return;
            if (menu && menu.canClose !== false) void post('menuClose');
            else if (input && input.cancel !== false) void post('inputCancel');
        };
        window.addEventListener('keydown', key);
        return () => window.removeEventListener('keydown', key);
    }, [menu, input]);
    useEffect(() => {
        if (!progress) return;
        const timer = setTimeout(() => setProgress(null), (Number(progress.duration) || 1000) + 150);
        return () => clearTimeout(timer);
    }, [progress]);
    const position = menu?.position || 'center';
    const horizontal = position.includes('right') ? 'flex-end' : position.includes('left') ? 'flex-start' : 'center';
    const vertical = position.includes('top') ? 'flex-start' : position.includes('bottom') ? 'flex-end' : 'center';
    return (
        <>
            {text && (
                <div id="textui">
                    <div className="textui-head">
                        {text.icon && (
                            <span className="textui-icon">
                                <Icon value={text.icon} color={text.iconColor} />
                            </span>
                        )}
                        <div className="textui-copy">
                            {text.title && <div className="textui-title">{text.title}</div>}
                            <div className="textui-description">{text.description || text.text}</div>
                        </div>
                    </div>
                    {text.options?.length > 0 && (
                        <div className="textui-options">
                            {text.options.map((option: Data, index: number) => (
                                <div className="textui-option" key={index}>
                                    <span className="textui-option-icon">
                                        <Icon value={option.icon} color={option.iconColor} />
                                    </span>
                                    <span className="textui-option-label">
                                        {option.label || option.title || option.description}
                                    </span>
                                    <span className="textui-key">{option.keybind || option.key}</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}
            {progress && (
                <div id="progress" key={progress.start}>
                    <div className="progress-label">{progress.label || 'Processing...'}</div>
                    <div className="progress-track">
                        <div
                            id="progress-fill"
                            style={{
                                width: '100%',
                                animation: `dt-progress ${Number(progress.duration) || 1000}ms linear`,
                            }}
                        />
                    </div>
                </div>
            )}
            {(menu || input) && (
                <div
                    id="modal"
                    style={{
                        justifyContent: input ? 'center' : horizontal,
                        alignItems: input ? 'center' : vertical,
                    }}
                >
                    {menu && (
                        <div id="menu" className="panel">
                            <div className="panel-head">
                                <div>
                                    <div className="eyebrow">SURVIVOR TERMINAL</div>
                                    <h1>{menu.title || 'Menu'}</h1>
                                    <p>{menu.subtitle}</p>
                                </div>
                                {menu.canClose !== false && (
                                    <button className="close" onClick={() => void post('menuClose')}>
                                        ×
                                    </button>
                                )}
                            </div>
                            <div id="menu-items">
                                {(menu.items || []).map((option: Data, index: number) => (
                                    <button
                                        className="menu-item"
                                        key={index}
                                        disabled={option.disabled || option.readOnly}
                                        onClick={() =>
                                            void post('menuSelect', {
                                                index: index + 1,
                                            })
                                        }
                                    >
                                        {option.icon && (
                                            <span className="menu-icon">
                                                <Icon value={option.icon} color={option.iconColor} />
                                            </span>
                                        )}
                                        {image(option.image) && (
                                            <img
                                                className="menu-image"
                                                src={option.image}
                                                alt=""
                                                onError={(event) => (event.currentTarget.style.display = 'none')}
                                            />
                                        )}
                                        <span className="menu-copy">
                                            <strong>{option.label || option.title || `Option ${index + 1}`}</strong>
                                            {option.description && <small>{option.description}</small>}
                                            {option.metadata &&
                                                Object.entries(option.metadata).map(
                                                    ([metadataKey, metadataValue]: [string, any]) => (
                                                        <small className="menu-metadata" key={metadataKey}>
                                                            {typeof metadataValue === 'object' && metadataValue
                                                                ? `${metadataValue.label || metadataKey}: ${metadataValue.value ?? ''}`
                                                                : Array.isArray(option.metadata)
                                                                  ? String(metadataValue)
                                                                  : `${metadataKey}: ${metadataValue}`}
                                                        </small>
                                                    ),
                                                )}
                                            {option.progress != null && Number.isFinite(Number(option.progress)) && (
                                                <progress
                                                    max={100}
                                                    value={Math.max(0, Math.min(100, Number(option.progress)))}
                                                    style={{
                                                        accentColor: option.progressColor,
                                                    }}
                                                />
                                            )}
                                        </span>
                                        <span className="menu-right">{option.rightLabel}</span>
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}
                    {input && (
                        <form
                            id="input"
                            className="panel"
                            key={JSON.stringify(input)}
                            onSubmit={(event) => {
                                event.preventDefault();
                                void post('inputSubmit', {
                                    values: Object.fromEntries(new FormData(event.currentTarget)),
                                });
                            }}
                        >
                            <div className="panel-head">
                                <div>
                                    <div className="eyebrow">SURVIVOR TERMINAL</div>
                                    <h1>{input.title || 'INPUT'}</h1>
                                    <p>{input.description}</p>
                                </div>
                                {input.cancel !== false && (
                                    <button type="button" className="close" onClick={() => void post('inputCancel')}>
                                        ×
                                    </button>
                                )}
                            </div>
                            <div id="input-fields">
                                {(input.fields || []).map((field: Data, index: number) => {
                                    const props = {
                                        id: `field-${index}`,
                                        name: field.name || `field${index + 1}`,
                                        defaultValue: field.default,
                                        required: !!field.required,
                                        placeholder: field.placeholder,
                                        min: field.min,
                                        max: field.max,
                                        step: field.step,
                                    };
                                    return (
                                        <div className="field" key={index}>
                                            <label htmlFor={props.id}>
                                                {field.label || field.name || `Field ${index + 1}`}
                                            </label>
                                            {field.type === 'select' ? (
                                                <select {...props}>
                                                    {(field.options || []).map((option: any, optionIndex: number) => (
                                                        <option
                                                            key={optionIndex}
                                                            value={typeof option === 'object' ? option.value : option}
                                                        >
                                                            {typeof option === 'object'
                                                                ? option.label || option.value
                                                                : option}
                                                        </option>
                                                    ))}
                                                </select>
                                            ) : field.type === 'textarea' ? (
                                                <textarea {...props} rows={field.rows || 3} />
                                            ) : (
                                                <input {...props} type={field.type || 'text'} />
                                            )}
                                        </div>
                                    );
                                })}
                            </div>
                            <div className="input-actions">
                                {input.cancel !== false && (
                                    <button type="button" onClick={() => void post('inputCancel')}>
                                        {input.cancelText || 'CANCEL'}
                                    </button>
                                )}
                                <button type="submit" className="primary">
                                    {input.submitText || 'CONFIRM'}
                                </button>
                            </div>
                        </form>
                    )}
                </div>
            )}
            <iframe
                id="ecosystem-dialogue"
                title="Dialogue"
                src="../dialogue/dist/index.html"
                style={{
                    position: 'fixed',
                    inset: 0,
                    width: '100%',
                    height: '100%',
                    border: 0,
                    display: dialogue ? 'block' : 'none',
                    background: 'transparent',
                    zIndex: 90,
                }}
            />
        </>
    );
}
const root = document.getElementById('root');
if (root) createRoot(root).render(<App />);
