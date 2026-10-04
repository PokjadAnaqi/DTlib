# DTlib Notify

DTlib v1.0.3 provides dedicated client and server notification modules:

```text
modules/notify/client.lua
modules/notify/server.lua
modules/notify/*/client.lua
```

When `lation_ui` is active, notifications are rendered by Lation Modern UI. Otherwise DTlib uses its native notification NUI.

## Types

Supported DT notification types:

```text
info
warning
success
error
```

Compatibility aliases are normalized automatically:

```text
inform / primary / default -> info
warn                       -> warning
danger / fail / failed     -> error
```

## Client

```lua
DT.Notify({
    title = 'VEHICLE SYSTEM',
    description = 'Engine oil replaced successfully.',
    type = 'success',
    duration = 5000,
    position = 'top-right',
    size = 'md',
    icon = 'fa-solid fa-oil-can'
})
```

The string shorthand remains supported:

```lua
DT.Notify('VEHICLE SYSTEM', 'Engine oil is overdue.', 'warning')
```

Client export:

```lua
exports.DTlib:Notify({
    title = 'SYSTEM',
    message = 'Ready',
    type = 'info'
})
```

## Server

Send to one player:

```lua
DT.Notify(source, {
    title = 'REWARD',
    message = 'Reward added to inventory.',
    type = 'success'
})
```

String shorthand:

```lua
DT.Notify(source, 'REWARD', 'Reward added to inventory.', 'success')
```

Broadcast:

```lua
DT.NotifyAll({
    title = 'SERVER',
    message = 'Airdrop inbound.',
    type = 'warning'
})
```

Selected players:

```lua
DT.NotifyPlayers({12, 24, 31}, {
    title = 'SQUAD',
    message = 'Objective updated.',
    type = 'info'
})
```

Server exports:

```lua
exports.DTlib:Notify(source, data)
exports.DTlib:NotifyAll(data)
exports.DTlib:NotifyPlayers(players, data)
```

## Lation-specific notify options

DTlib passes these supported fields through to Lation:

```lua
DT.Notify({
    id = 'maintenance-warning',
    title = 'MAINTENANCE',
    message = 'Engine oil service is overdue.',
    type = 'warning',
    duration = 6000,
    position = 'top-right',
    size = 'lg',
    icon = 'fa-solid fa-triangle-exclamation',
    iconColor = '#D0A45E',
    iconAnimation = 'pulse',
    bgColor = '#111513',
    txtColor = '#E8ECEA',
    titleColor = '#FFFFFF',
    sound = {
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        name = 'SELECT'
    }
})
```

Lation positions supported by DTlib notify are `top-left`, `top`, `top-right`, `center-left`, `center-right`, `bottom-left`, `bottom`, and `bottom-right`. `top-center`/`bottom-center` are accepted as DT aliases.


## Automatic item label resolution

DTlib v1.0.10 resolves registered inventory item IDs to their player-facing labels before a notification is displayed.

For example, a message sent as:

```lua
DT.Notify(source, {
    title = 'BREACH REQUIRED',
    message = 'Missing required item: airdrop_breach_tool',
    type = 'error'
})
```

will display the configured inventory label (for example `Airdrop Breach Tool`) instead of the internal item ID when that item exists in the active registry.

Structured item fields are also supported:

```lua
DT.Notify(source, {
    title = 'BREACH REQUIRED',
    message = 'Missing required item: airdrop_breach_tool',
    item = 'airdrop_breach_tool',
    type = 'error'
})
```

The resolver supports ox_inventory / DT Grid Inventory first and falls back to QBX, QBCore, or ESX item registries where available.

To disable automatic item-label replacement globally:

```lua
DTConfig.UI.resolveItemLabels = false
```

Or from `server.cfg`:

```cfg
DTConfig.UI.resolveItemLabels = false -- settings/sharedConfig.lua
```

The item registry API is also available server-side:

```lua
local data = DT.Inventory.GetItemData('airdrop_breach_tool')
local label = DT.Inventory.GetItemLabel('airdrop_breach_tool')
```
