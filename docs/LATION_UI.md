# Lation UI support

DTlib v1.0.3 can use `lation_ui` as the UI backend while keeping the public DT API stable.

## Load order

If Lation Modern UI is installed, start it before DTlib:

```cfg
ensure lation_ui
ensure DTlib
```

Lation recommends loading `lation_ui` before other resources. DTlib does not bundle or require Lation UI; it remains an optional backend.

## Adapter selection

```cfg
# Detect lation_ui when running, otherwise use DTlib native UI.
DTConfig.Adapters.ui = 'auto'

# Force Lation UI. If it is unavailable DTlib calls fall back to the native UI.
DTConfig.Adapters.ui = 'lation_ui'

# Always use DTlib native UI.
DTConfig.Adapters.ui = 'native'
```

`DT.UI.Name()` returns `lation_ui` or `native`.

```lua
print(DT.UI.Name())
print(DT.UI.UsingLation())
```

The server `dtlib:status` output also displays the active UI backend.

## Supported DT UI calls

The existing DT API automatically routes these calls to Lation when available:

- `DT.Notify`
- `DT.Progress`
- `DT.ProgressActive`
- `DT.ProgressCancel`
- `DT.TextUI.Show`
- `DT.TextUI.Hide`
- `DT.TextUI.IsOpen`
- `DT.Menu.Open`
- `DT.Menu.Close`
- `DT.Input.Await`
- `DT.Input.Close`
- `DT.Minigame.SkillCheck`
- `DT.Minigame.SignalBreach`
- `DT.Minigame.PatternLock`

If Lation is not running, DTlib uses its built-in NUI implementation.

## Progress example

```lua
local success = DT.Progress({
    label = 'Repairing vehicle',
    description = 'Installing replacement components...',
    duration = 5000,
    icon = 'fa-solid fa-screwdriver-wrench',
    canCancel = true,
    disable = {
        move = true,
        car = true,
        combat = true
    }
})
```

With Lation active, `anim`, `prop`, `steps`, `iconColor`, `iconAnimation`, `color`, and the Lation progress state options are passed through.

## Text UI example

```lua
DT.TextUI.Show({
    title = 'TERMINAL',
    description = 'Access survivor terminal',
    keybind = 'E',
    icon = 'fa-solid fa-terminal',
    position = 'right-center'
})

DT.TextUI.Hide()
```

## Menu example

```lua
DT.Menu.Open({
    title = 'VEHICLE SYSTEM',
    position = 'offcenter-right',
    items = {
        {
            label = 'Vehicle status',
            description = 'View mileage and maintenance status',
            icon = 'fa-solid fa-car',
            onSelect = function()
                print('selected')
            end
        }
    }
})
```

## Input example

```lua
local result = DT.Input.Await({
    title = 'CONFIGURE MACHINE',
    fields = {
        {
            name = 'label',
            type = 'text',
            label = 'Label',
            required = true
        },
        {
            name = 'amount',
            type = 'number',
            label = 'Amount',
            default = 1
        }
    }
})

if result then
    print(result.label, result.amount)
end
```

DTlib maps `type = 'text'` to Lation's `input` field and maps Lation's ordered result back to named DT fields when `name` is supplied.


## Vertical TextUI controls (v1.0.9)
`DT.TextUI.Show` accepts `title`, `description`, and an `options` array. When Lation UI is active, the array is forwarded to `showText` as native multi-option rows with per-row icon and keybind support. DTlib placement uses this automatically.

```lua
DT.TextUI.Show({
    title = 'CONTROLS',
    description = 'Place the object where desired',
    options = {
        { label = 'Move / Translate', icon = 'fa-solid fa-up-down-left-right', keybind = 'W' },
        { label = 'Rotate', icon = 'fa-solid fa-rotate', keybind = 'R' },
        { label = 'Confirm', icon = 'fa-solid fa-check', keybind = 'ENTER' },
        { label = 'Cancel', icon = 'fa-solid fa-xmark', keybind = 'ESC' },
    }
})
```


## Minigames (v1.0.12)

DTlib wraps Lation Modern UI Skill Check, Signal Breach, and Pattern Lock under `DT.Minigame`. The minigame provider is independent from the normal DT UI adapter, so a server may keep another TextUI/notification backend while still using Lation for minigames.

See `docs/MINIGAMES.md` for full examples and cancellation/state APIs.

## v1.2.0 ecosystem expansion

See [ECOSYSTEM.md](ECOSYSTEM.md) for Lation Alert/List Menu, per-module UI settings,
okok providers, embedded community adapters and installation details.
See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) for all provider categories.
