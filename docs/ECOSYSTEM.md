# DTlib v1.2.0 — Lation, okok and community adapters

Baseline: user-supplied DTlib v1.1.1 CONFIG_ONLY_DISCORD_CONVARS.
The default resource name is still `DTlib`, with `fx_version 'cerulean'`.

## Installation

1. Replace the existing `DTlib` folder with the included folder.
2. Start the framework/database/inventory and any chosen provider resources before DTlib.
3. Start DTlib before DT ecosystem resources. Consumers still use `@DTlib/init.lua`.
4. Restart consumers after replacing DTlib because GetObject functions are cached by consumers.

`community_bridge` is **not required**. Its adapter source pack is bundled under
`compat/community/`, using a private Lua environment and `DTlib:ecosystem:*` events.
The separately purchased/installed provider resources remain necessary; this ZIP does
not contain okok products or Lation UI itself. No changes to cd_easytime are required.

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
checks okokTextUI and the remaining bundled providers. Notify has its own setting.
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
local sent = DT.Phone.SendEmail(source, 'recipient@example.com', 'Subject', 'Message')

-- client
DT.Fuel.SetFuel(vehicle, 75.0)
DT.VehicleKey.GiveKeys(vehicle, plate)
DT.TextUI.Show({ description = 'Access Terminal', keybind = 'E', position = 'right-center' })
```

Banking refers to society/account balances, not player wallets. Player wallet APIs
remain `DT.Player.GetMoney/AddMoney/RemoveMoney`. okokTextUI supports left/right and
its named colors; `color='darkblue'` and `playSound=false` are the defaults.

## Community adapter coverage

22 adapter categories, 153 provider directories, pinned to community_bridge
v0.13.6. Full provider lists and method names are in `ECOSYSTEM_PROVIDERS.json` and
`SUPPORT_MATRIX.md`. Each namespace preserves community_bridge method signatures.

Existing DT APIs preserve their DT signatures. Use `DT.Ecosystem.Inventory`,
`DT.Ecosystem.Framework`, etc. when you specifically need the upstream signature.
For new categories, `DT.Fuel`, `DT.Banking`, `DT.Phone`, `DT.Clothing`, `DT.Housing`,
`DT.Doorlock`, `DT.Dispatch`, `DT.VehicleKey`, `DT.Skills`, `DT.BossMenu`, `DT.Shops`,
`DT.Dialogue` and `DT.Zones` expose their compatibility methods directly.

```lua
local providers = DT.Ecosystem.List('phone')
local selected = DT.Ecosystem.Provider('phone')
local status = DT.Ecosystem.Status()
-- All original provider methods are exposed under the category namespace.
local resourceName = DT.Ecosystem.Phone.GetResourceName()
```

`DTConfig.Ecosystem.providers` selects exactly one backend per category. It accepts
a provider directory name or actual resource name. `auto` follows explicit DT
adapter settings when present, then the category's provider priority. Restart DTlib
and consuming resources after changing a selected provider. The pack never calls
exports on stopped resources as a selection fallback. Missing backend or unsupported
method returns nil and a reason; provider-specific unsupported methods may retain
their upstream false/nil return behavior.

Extra inventories are also registered into the existing `DT.Inventory` API for
items, counts, capacity, slots, metadata, registry access and server stash methods
where their backends implement them. ox_inventory and qb-inventory retain the
baseline adapters. Inventory metadata matching, stash ownership and special features
remain backend-specific; use the JSON method list and upstream resource docs.
`sleepless_interact` also joins the existing DT.Target selection with community
bridge's partial capability set (box areas use coordinate anchors; no poly adapter).

## Utilities and defaults

`DT.Ecosystem.Utility(name)` loads the bundled helper only when requested. Helpers:
Ids, Tables, Prints, Math, LA, Callback, SQL, Logs, Scaleform, Placeable,
PlaceableObject, Utility, Raycast, Point, Particle, Anim, Cutscene, Vehicles,
Entity, Marker, Shell, Version. Client/server-specific helpers return a wrong-side
reason on the other runtime. Some legacy helpers need their original optional
resources or game natives. `DT.Language.Locale` and `DT.VersionChecker` are also
available. Version checks run only when called. DT's native Placement and Waypoint
remain the primary placement/navigation APIs.

Native Shops, Skills and Dialogue default to `native` inside the compatibility
pack. Set their provider to `disabled` to disable them. Native shop checkout requires
a server-opened shop session, validates quantity/access/proximity, checks stock and
capacity, and refunds failed delivery. Dialogue uses a dedicated embedded view.
Custom persistent gameplay data such as skill metadata is managed by the selected
framework; this update does not migrate a live server's data automatically.

## Validation

- Standard Lua 5.4 compilation of all Lua files; native Cfx hashes are normalized only
  in the test compiler for baseline files.
- Client and server manifest-load checks with Cfx stubs.
- 219 provider/side initialization combinations in an isolated mock runtime.
- Behavioral tests for alert payloads/results, named input mapping, Lation steps,
  list-menu callback count/live option updates and per-module provider precedence.
- Export/event argument tests for okok Banking, Fuel, Garage keys and Phone.

These are static and mock-contract checks. Actual paid provider resources and a live
FiveM server were unavailable here. Verify provider-specific features in game after
installation. Provider manifests/exports can differ by purchased version.

Discord configuration remains `dt_eco_discord_bot_token` and
`dt_eco_discord_guild_id` via the existing DTConfig.Discord fields. No token is included.
