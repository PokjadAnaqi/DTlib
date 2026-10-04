# DTlib TextUI

DTlib v1.0.9 supports structured vertical TextUI.

```lua
DT.TextUI.Show({
    title = 'CONTROLS',
    description = 'Place the object where desired',
    position = 'right-center',
    icon = 'fa-solid fa-cube',
    options = {
        { label = 'Move / Translate', keybind = 'W', icon = 'fa-solid fa-up-down-left-right' },
        { label = 'Rotate', keybind = 'R', icon = 'fa-solid fa-rotate' },
        { label = 'Confirm', keybind = 'ENTER', icon = 'fa-solid fa-check', iconColor = '#2dd4a7' },
        { label = 'Cancel', keybind = 'ESC', icon = 'fa-solid fa-xmark', iconColor = '#ef6464' },
    }
})
```

Provider behaviour:
- `lation_ui`: uses `showText` with native `options` rows.
- `ox_lib`: uses exported TextUI functions with compact multiline content and max-width styling.
- `native`: uses DTlib NUI vertical control card.

UI auto-detection priority is `lation_ui`, then `ox_lib`, then DTlib native. Set `DTConfig.Adapters.ui` in `settings/sharedConfig.lua` to `native`, `lation_ui`, or `ox_lib` to force a provider.


## Placement camera compatibility

Lation TextUI is passive during DTlib placement and does not own camera input. DTlib v1.0.18 uses a prop-centred scripted orbit camera by default: drag **LMB on empty space** to orbit around the prop, use LMB on a gizmo axis to manipulate that axis, and use the mouse wheel to zoom. No server.cfg/convar is required. A specific placement call may use `camera = 'gameplay'` when the normal gameplay/PED camera is intentionally desired.
