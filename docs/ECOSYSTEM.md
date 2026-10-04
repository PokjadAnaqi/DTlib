# DTlib 1.3.0-beta.2 — standalone provider library

DTlib keeps its native core, placement, waypoint and configuration APIs.
The default resource name is still `DTlib`, with `fx_version 'cerulean'`.

## Installation

1. Replace the existing `DTlib` folder with the included folder.
2. Start the framework/database/inventory and any chosen provider resources before DTlib.
3. Start DTlib before DT ecosystem resources. Consumers still use `@DTlib/init.lua`.
4. Restart consumers after replacing DTlib because GetObject functions are cached by consumers.

DTlib runs its own local Lua provider modules declared in the manifest. Vendor resources remain optional, separately installed backends. There is no bundled external runtime or external dialogue iframe.

## Per-module UI selection

Edit `settings/sharedConfig.lua`:

```lua
DTConfig.Adapters.ui = 'lation_ui'
DTConfig.Adapters.notify = 'okokNotify' -- independent of the common UI choice
DTConfig.Adapters.textui = 'okokTextUI'
DTConfig.Adapters.progress = 'lation_ui'
DTConfig.Adapters.input = 'lation_ui'
DTConfig.Adapters.menu = 'lation_ui'
DTConfig.Adapters.listmenu = 'lation_ui'
DTConfig.Adapters.alert = 'lation_ui'
```

`auto` inherits `Adapters.ui` for alert, input, menu, list menu, text UI and progress.
If the shared UI choice is also auto, Lation is preferred, then ox_lib. Text UI also
checks okokTextUI and the remaining registered providers. Notify has its own setting.
A stopped resource cannot become a selected provider. Existing DT fallback behavior
remains available. List menus need a modern Lation UI version exposing its List Menu
exports or ox_lib; they return `provider_unavailable` otherwise.

## Lation UI APIs

| Component | DT API | Lation export |
| --- | --- | --- |
| Alert | `DT.Alert.Await(data)`, `DT.Alert.Close()` | `alert`, `closeAlert` |
| Notify | `DT.Notify(data)` / server `DT.Notify(source, data)` | `notify` |
| Text UI | `DT.TextUI.Show(data)`, `Hide()`, `IsOpen()` | `showText`, `hideText`, `isOpen` |
| Progress including steps | `DT.Progress(data)`, `ProgressActive()`, `ProgressCancel()` | `progressBar`, `progressActive`, `cancelProgress` |
| Input | `DT.Input.Await(data)`, `Close()` | `input`, `closeInput` |
| Context menu | `DT.Menu.Open(data, callback)`, `Close()` | `registerMenu`, `showMenu`, `hideMenu` |
| List menu | `DT.ListMenu.Register`, `Show`, `Open`, `Close`, `SetOptions`, `GetOpen` | `registerListMenu`, `showListMenu`, `hideListMenu`, `setListMenuOptions`, `getOpenListMenu` |
| Minigames retained | `DT.Minigame.SkillCheck`, `SignalBreach`, `PatternLock` and cancellation/activity APIs | Lation minigame exports |

### Alert

```lua
local result = DT.Alert.Await({
    header = 'RECYCLE MACHINE',
    content = 'Remove this machine?',
    icon = 'fa-solid fa-triangle-exclamation',
    type = 'warning', size = 'md', cancel = true,
    labels = { confirm = 'REMOVE', cancel = 'CANCEL' },
    callouts = {{ label = 'Warning', description = 'Stored items will be affected.', type = 'warning' }}
})
if result == 'confirm' then -- perform the server-validated action
end
```

Returns `confirm` / `cancel`. Busy/error cases may return nil and a reason. Without
Lation/ox, the native fallback uses a confirmation form; visual Lation callouts are
provider-specific. Awaiting alert/input/progress now uses a local consumer coroutine
through the DT UI event bridge, following placement/minigame bridge behavior.

### Multi-step progress

```lua
local completed, reason = DT.Progress({
    label = 'REPAIRING', duration = 9000, canCancel = true,
    icon = 'fa-solid fa-screwdriver-wrench',
    steps = {
        { description = 'Inspecting components...' },
        { description = 'Replacing damaged parts...' },
        { description = 'Testing power...' }
    },
    disable = { move = true, car = true, combat = true }
})
```

The `steps` array uses Lation's descriptions with one overall duration. DT forwards
animation/prop options and the Lation ragdoll, cuffed, falling/swimming controls.
Step presentation is a Lation capability, not a promise of identical visuals on
other progress providers.

### Input

```lua
local values = DT.Input.Await({
    title = 'SETTINGS',
    fields = {
        { name = 'name', type = 'input', label = 'Name', required = true },
        { name = 'count', type = 'number', label = 'Count', min = 1, default = 1 }
    }
})
if values then print(values.name, values.count) end
```

Lation field options are retained. `text` aliases to `input`. When fields have
`name`, DT maps returned array values to those names. Cancellation returns nil.

### Keyboard list menu

```lua
DT.ListMenu.Register({
    id = 'machine_settings', title = 'MACHINE SETTINGS', position = 'top-right',
    disableInput = true,
    onSideScroll = function(selected, index, args) end,
    onCheck = function(selected, checked, args) end,
    onSelected = function(selected, secondary, args) end,
    onClose = function(key) end,
    options = {
        { label = 'Mode', values = { 'AUTO', 'MANUAL' }, defaultIndex = 1, close = false },
        { label = 'Enabled', checked = true },
        { label = 'Confirm', icon = 'fa-solid fa-check', args = { action = 'save' } }
    }
}, function(selected, scrollIndex, args, checked)
    -- The selection callback is invoked once.
end)
DT.ListMenu.Show('machine_settings', 1)
DT.ListMenu.SetOptions('machine_settings', { label = 'Enabled', checked = false }, 2)
local id = DT.ListMenu.GetOpen()
-- DT.ListMenu.Close(true) also invokes onClose.
```

Direct exports: `RegisterListMenu`, `ShowListMenu`, `ListMenuOpen`, `HideListMenu`,
`SetListMenuOptions`, `GetOpenListMenu`. Checkbox and side-scroll callbacks follow
the provider's documented behavior; events receive the option's args table.

## okok ecosystem support

| Provider | API | Runtime |
| --- | --- | --- |
| okokNotify | `DT.Notify` | client + DT server notification relay |
| okokTextUI | `DT.TextUI.Show/Hide/IsOpen` | client |
| okokBanking | `DT.Banking.GetAccountMoney/AddAccountMoney/RemoveAccountMoney` | server |
| okokGarage | `DT.VehicleKey.GiveKeys/RemoveKeys` | client |
| okokGasStation | `DT.Fuel.GetFuel/SetFuel` | client |
| okokPhone | `DT.Phone.GetPlayerPhone/SendEmail` | server; SendEmail also on client |

```lua
DTConfig.Ecosystem.providers.banking = 'okokBanking'
DTConfig.Ecosystem.providers.vehiclekey = 'okokGarage'
DTConfig.Ecosystem.providers.fuel = 'okokGasStation'
DTConfig.Ecosystem.providers.phone = 'okokPhone'

-- server
local balance = DT.Banking.GetAccountMoney('police')
local added = DT.Banking.AddAccountMoney('police', 500, 'Reward')
local number = DT.Phone.GetPlayerPhone(source)
local sent = DT.Phone.SendEmail(source, 'sender@example.com', 'Subject', 'Message')

-- client
DT.Fuel.SetFuel(vehicle, 75.0)
DT.VehicleKey.GiveKeys(vehicle, plate)
DT.TextUI.Show({ description = 'Access Terminal', keybind = 'E', position = 'right-center' })
```

Banking refers to society/account balances, not player wallets. Player wallet APIs
remain `DT.Player.GetMoney/AddMoney/RemoveMoney`. okokTextUI supports left/right and
its named colors; `color='darkblue'` and `playSound=false` are the defaults.

## Provider registry

The 22 categories retain 153 named provider profiles, including native defaults. See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) and [ECOSYSTEM_PROVIDERS.json](ECOSYSTEM_PROVIDERS.json). The JSON records the callable methods on each runtime side; an installed vendor version must expose the matching exports/events.

Existing `DT.Inventory`, `DT.Framework`, `DT.Menu` and `DT.Target` keep their original DT API. Access normalized provider contracts through `DT.Ecosystem.Inventory`, `DT.Ecosystem.Framework`, etc. Other categories also expose `DT.Fuel`, `DT.Banking`, `DT.Phone`, `DT.Clothing`, `DT.Dispatch`, `DT.VehicleKey`, `DT.Skills`, `DT.BossMenu`, `DT.Shops`, `DT.Dialogue` and `DT.Zones`.

```lua
local api, reason = DT.Ecosystem.Get('banking', 'okokBanking')
if api and DT.Ecosystem.Supports('banking', 'AddAccountMoney', 'okokBanking') then
    api.AddAccountMoney('police', 250, 'Reward')
end
local methods = DT.Ecosystem.List('inventory')
local status = DT.Ecosystem.Status()
```

Use `DTConfig.Ecosystem.providers` to choose one backend per category. `auto` follows category adapter settings, then started providers, then a native default where present. Explicit choices do not silently select a different ecosystem provider. Stopped resources are never invoked by the registry. Missing providers return `nil, reason`; unsupported operations are absent from the provider API and `Supports` returns false. `List.methods` reflects the initialized API; `declaredMethods` is the category discovery list.

Inventory provider contracts use `AddItem(src, item, count, slot, metadata)`, `SetMetadata(src, item, slot, metadata)`, `RegisterShop(name, items, coords, groups)` and `OpenStash(src, kind, id)`. The main DT inventory API keeps metadata before slot. Plate migration methods use vendor exports and/or the documented legacy database tables, so confirm your installed schema before using them.

Server phone calls use `SendEmail(src, sender, title, message)`; client calls omit `src` and address only the caller's phone. Client mail and dispatch requests are rate limited. Boss menu opening checks the caller's job and boss state on the server. Door lock changes are server-only; QB door changes broadcast the state and do not provide persistent state management.

## DT utilities and native features

`DT.Ecosystem.Utility(name)` and `Require(name)` return DTlib modules. Supported names: `tables`, `ids`, `math`, `callback`, `database`, `logger`, `vehicle`, `waypoint`, `placement`, `zones`, `utility`, `state`, `resource`. Names are lowercase. `Require` does not load Lua paths or execute another resource's files. Utility objects use the DT APIs described elsewhere in this documentation.

Native shops validate server sessions, quantity, account, stock, groups and proximity; failed delivery refunds payment. Native skills store XP in server memory, cleared on disconnect; choose an installed skill provider for persistent progression. Client XP mutation is intentionally unavailable.

Dialogue presents text and choices through DT.Menu and resolves the selected option ID. `characterOptions` remains accepted for call compatibility; this beta does not add a cinematic camera. Zones use DTlib geometry and ownership cleanup, even when selecting the `ox_lib` or `PolyZone` compatibility profile. Use `DT.Zone` directly for independent native geometry.

Clothing uses `{model, components, props}` for native/QB/ESX normalized snapshots; appearance providers return their full vendor appearance. QB/ESX conversion helpers map components and props. Native snapshots do not include facial genetics or tattoos. ESX Save reads the full current skin and writes the `users.skin` record; other persistence uses the vendor's save API. Native clothing has no appearance editor. Unsupported vendor operations and former no-op methods are not reported as supported.

See [VALIDATION.md](VALIDATION.md) for checks and [MIGRATION.md](MIGRATION.md) for the beta's changes. Discord remains configured through `dt_eco_discord_bot_token` and `dt_eco_discord_guild_id`; no token is included.

## Full adapter pack

Beta.2 additionally includes every runtime module/utility/locale/web source from the full provider pack. `DT.AdapterPack` exposes complete source signatures. Existing DT contracts remain; see [ADAPTER_PACK.md](ADAPTER_PACK.md) for full APIs, one-provider-per-category selection and utility names.
