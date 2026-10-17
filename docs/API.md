# DTlib API

## Core

```lua
DT.GetVersion()
DT.GetAdapters()
DT.Resource.Started('resource_name')
```

## UI adapter

```lua
DT.UI.Name()          -- 'lation_ui', 'ox_lib', or 'native'
DT.UI.UsingLation()   -- boolean
DT.UI.UsingOxLib()    -- boolean
```

Set `DTConfig.Adapters.ui = 'auto'` in `settings/sharedConfig.lua` to prefer Lation, then ox_lib, then the DTlib native UI.

## Notifications

Client:
```lua
DT.Notify({
    title = 'VEHICLE SYSTEM',
    description = 'Engine oil replaced.',
    type = 'success',
    duration = 5000,
    position = 'top-right',
    size = 'md',
    icon = 'fa-solid fa-oil-can'
})
```

Server:
```lua
DT.Notify(source, { title = 'REWARD', message = 'Reward delivered.', type = 'success' })
DT.NotifyAll({ title = 'SERVER', message = 'Airdrop inbound.', type = 'warning' })
DT.NotifyPlayers({12, 24}, { title = 'SQUAD', message = 'Objective updated.', type = 'info' })
```

See `docs/NOTIFY.md` for all Lation-compatible fields.

## Client UI

```lua
local success, reason = DT.Progress({
    duration = 5000,
    label = 'Repairing vehicle...',
    canCancel = true,
    disable = { combat = true, car = true }
})
DT.ProgressActive()
DT.ProgressCancel()

DT.TextUI.Show('[E] ACCESS TERMINAL')
DT.TextUI.Hide()
DT.TextUI.IsOpen()

DT.Menu.Open({
    title = 'TERMINAL',
    items = {
        { label = 'Open storage', serverEvent = 'myresource:openStorage' }
    }
})

DT.Menu.Close()

local values = DT.Input.Await({
    title = 'CONFIGURE MACHINE',
    fields = {
        { name = 'label', label = 'Label', required = true },
        { name = 'amount', label = 'Amount', type = 'number', default = 1 }
    }
})
DT.Input.Close()

local result = DT.Alert.Await({
    header = 'CONFIRM',
    content = 'Continue?',
    cancel = true
})
DT.Alert.Close()
```

DTlib routes supported UI calls through the selected provider: `lation_ui`, `ox_lib`, or the built-in native NUI. `DT.Alert` currently uses the ox_lib alert dialog when ox_lib is the selected UI provider.

## Callbacks

Server:
```lua
DT.Callback.Register('myresource:getData', function(source, id)
    return { id = id, owner = DT.Player.GetIdentifier(source) }
end)
```

Client:
```lua
local data = DT.Callback.Await('myresource:getData', 10)
```

Client callbacks can also be registered and awaited from server with `DT.Callback.AwaitClient(source, name, ...)`.

## Player / framework (server)

```lua
DT.Framework.Name()
DT.Player.Get(source)
DT.Player.GetPlayers()
DT.Player.GetIdentifier(source)
DT.Player.GetName(source)
DT.Player.GetJob(source)
DT.Player.GetGang(source)
DT.Player.GetMoney(source, 'cash')
DT.Player.AddMoney(source, 'cash', 100, 'reward')
DT.Player.RemoveMoney(source, 'cash', 100, 'purchase')
DT.Player.GetMeta(source, 'key')
DT.Player.SetMeta(source, 'key', value)
DT.Player.HasGroup(source, { police = 2 })
```

## Inventory (client)

```lua
DT.Inventory.Open('stash', 'stash_id')
DT.Inventory.UseSlot(1)
DT.Inventory.GetCurrentWeapon()
DT.Inventory.GetCount('water')
DT.Inventory.Search('slots', 'water')
DT.Inventory.GetItems()
DT.Inventory.GetWeight()
DT.Inventory.GetMaxWeight()
DT.Inventory.SuppressItemNotifications(true)
```

## Inventory (server)

```lua
DT.Inventory.Name()
DT.Inventory.CanCarry(source, 'water', 2)
DT.Inventory.CanCarryAmount(source, 'water')
DT.Inventory.CanCarryWeight(source, 5000)
DT.Inventory.CanSwapItem(source, 'water', 1, 'bandage', 1)
DT.Inventory.AddItem(source, 'water', 2, { quality = 100 })
DT.Inventory.RemoveItem(source, 'water', 1)
DT.Inventory.GetItem(source, 'water')
DT.Inventory.GetCount(source, 'water')
DT.Inventory.HasItem(source, 'water', 1)
DT.Inventory.Search(source, 'slots', 'water')
DT.Inventory.GetSlot(source, 1)
DT.Inventory.GetItems(source)
DT.Inventory.RegisterStash('stash_id', 'Storage', 30, 50000)
DT.Inventory.CreateTemporaryStash({ label = 'Temp', slots = 20, maxWeight = 20000 })
DT.Inventory.OpenStash(source, 'stash_id')
DT.Inventory.Clear('stash_id')
```

## Zones (client, native DTlib)

```lua
local zone = DT.Zone.Sphere({
    coords = vec3(0.0, 0.0, 72.0),
    radius = 2.0,
    onEnter = function() DT.TextUI.Show('[E] INTERACT') end,
    onExit = function() DT.TextUI.Hide() end
})

DT.Zone.Remove(zone)
```

Available: `Sphere`, `Box`, `Poly`.

## Target (client)

```lua
DT.Target.AddEntity(entity, {
    {
        label = 'Search',
        icon = 'fa-solid fa-magnifying-glass',
        onSelect = function(data) print('selected') end
    }
})
```

Available: global object/ped/player/vehicle options, local and network entities, models, sphere/box/poly zones, target disable/state/options queries, zone checks/removal, plus the existing QB target fallback where applicable.

## Database (server)

```lua
local rows = DT.Database.Query('SELECT * FROM players WHERE citizenid = ?', { citizenid })
local row = DT.Database.Single('SELECT * FROM players WHERE citizenid = ?', { citizenid })
local value = DT.Database.Scalar('SELECT COUNT(*) FROM players')
local id = DT.Database.Insert('INSERT INTO example (name) VALUES (?)', { name })
local changed = DT.Database.Update('UPDATE example SET name = ? WHERE id = ?', { name, id })
local prepared = DT.Database.Prepare('SELECT * FROM example WHERE id = ?', { id })
local raw = DT.Database.RawExecute('SELECT * FROM example WHERE id = ?', { id })
local ok = DT.Database.Transaction({
    {'UPDATE example SET name = ? WHERE id = ?', {name, id}},
    {'INSERT INTO audit (entry) VALUES (?)', {'updated'}}
})
```

## Security (server)

```lua
if not DT.Security.RateLimit(source, 'claim_reward', 3, 10000) then return end
if not DT.Security.RequireAdmin(source) then return end
```

Default admin ACE objects are `admin` or `god`, granted to the matching server principals:

```cfg
add_ace group.god god allow
add_ace group.admin admin allow
```

## Discord (server)

```lua
local discordId = DT.Discord.GetId(source)
local member = DT.Discord.GetMember(source)
local premium = DT.Discord.HasRole(source, 'ROLE_ID')
local avatar = DT.Discord.GetAvatar(source)
```

Token is read from `dt_eco_discord_bot_token`; guild ID from `dt_eco_discord_guild_id`.

## Vehicle (client)

```lua
local vehicle, distance = DT.Vehicle.GetClosest(nil, 5.0)
local plate = DT.Vehicle.GetPlate(vehicle)
local props = DT.Vehicle.GetProperties(vehicle)
DT.Vehicle.SetProperties(vehicle, props)
```

## Weather

```lua
DT.Weather.Name()
DT.Weather.GetCurrent()
DT.Weather.GetTime()
DT.Weather.GetData()
```


## Callback compatibility

```lua
DT.Callback.Register(name, callback)
DT.Callback.Unregister(name)
DT.Callback.Await(name, ...)
DT.Callback.Trigger(name, completion, ...)
DT.Callback.AwaitClient(source, name, ...) -- server
```

`Register` and `Trigger` accept normal Lua functions and Cfx cross-resource function references.

## Placement / Prop Gizmo (client)

```lua
DT.Placement.Provider()
DT.Placement.IsActive()
DT.Placement.GetState()
DT.Placement.Cancel()
DT.Placement.Confirm()
DT.Placement.Edit(entity, options)
DT.Placement.Start(entity, options)
DT.Placement.UseGizmo(entity, options)
DT.Placement.PlaceProp(model, options)
DT.Placement.SpawnProp(model, options)
```

`DT.PropPlacement` aliases `DT.Placement`.

Direct client exports are also available: `PlacementEdit`, `PlacementStart`, `PlacementUseGizmo`, `PlacementPlaceProp`, `PlacementCancel`, `PlacementConfirm`, and `PlacementIsActive`.

See `docs/PLACEMENT.md` for options, controls, callbacks and migration examples.

## Waypoint

Client:

```lua
local id = DT.Waypoint.Create({ coords = vec3(0.0, 0.0, 30.0), label = 'OBJECTIVE' })
DT.Waypoint.Update(id, { color = '#72a6c9' })
DT.Waypoint.Remove(id)
DT.Waypoint.SetMapSync(true)
```

Server:

```lua
local id = DT.Waypoint.Create(source, { coords = vec3(0.0, 0.0, 30.0), label = 'OBJECTIVE' })
DT.Waypoint.Update(id, { label = 'UPDATED' })
DT.Waypoint.Remove(id)
```

See `docs/WAYPOINTS.md` for all options.


## Item Registry

```lua
local item = DT.Inventory.GetItemData('airdrop_breach_tool')
local label = DT.Inventory.GetItemLabel('airdrop_breach_tool')
```

`GetItemLabel` returns the player-facing inventory label when the item is registered, or `nil` when the identifier is unknown.


## Minigames

```lua
DT.Minigame.Provider()
DT.Minigame.Available()

DT.Minigame.SkillCheck(title, difficulty, inputs, size)
DT.Minigame.SkillCheckActive()
DT.Minigame.CancelSkillCheck()

DT.Minigame.SignalBreach(title, difficulty, inputs, options)
DT.Minigame.SignalBreachActive()
DT.Minigame.CancelSignalBreach()

DT.Minigame.PatternLock(title, difficulty)
DT.Minigame.PatternLockActive()
DT.Minigame.CancelPatternLock()
```

Compatibility aliases: `DT.SkillCheck`, `DT.SignalBreach`, `DT.PatternLock`, plus `DT.UI.SkillCheck`, `DT.UI.SignalBreach`, and `DT.UI.PatternLock`.

See `docs/OX_SUPPORT.md` for the expanded OX adapter surface added in v1.0.22.


## Framework extensions (v1.0.22)

```lua
DT.Framework.Resource()
DT.Framework.Available(name)
DT.Framework.GetVersion()
DT.Framework.GetJobs()
DT.Framework.GetGangs()
DT.Framework.GetJob(name)
DT.Framework.GetGang(name)
DT.Framework.GetVehicles(filter)
DT.Framework.GetWeapons(filter)

DT.Player.GetPlayersData()
DT.Player.GetData(source)
DT.Player.GetByCitizenId(citizenid)
DT.Player.GetByUserId(userId)
DT.Player.GetByCharacterId(charId)
DT.Player.GetByIdentifier(identifier)
DT.Player.GetIdentifiers(source)
DT.Player.GetIdentifierByType(source, type)
DT.Player.GetCitizenId(source)
DT.Player.GetUserId(source)
DT.Player.GetCharacterId(source)
DT.Player.GetStateId(source)
DT.Player.GetName(source)
DT.Player.GetCoords(source)
DT.Player.GetGroups(source)
DT.Player.GetGroup(source, filter)
DT.Player.HasPrimaryGroup(source, filter)
DT.Player.SetJob(source, job, grade, onDuty)
DT.Player.SetJobDuty(source, onDuty)
DT.Player.SetGang(source, gang, grade)
DT.Player.SetMoney(source, type, amount, reason)
DT.Player.GetStatus(source, status)
DT.Player.SetStatus(source, status, value)
DT.Player.AddStatus(source, status, value)
DT.Player.RemoveStatus(source, status, value)
DT.Player.HasPermission(source, permission)
DT.Player.Save(source)
```

See `FRAMEWORK_SUPPORT.md` for backend-specific behavior.

## FiveM / Cfx helpers (v1.0.22)

```lua
DT.State.*
DT.Routing.*
DT.Entity.*
DT.Ace.*
DT.OneSync.*
```

See `FIVEM_SUPPORT.md` for client/server scope and examples.

```lua
DT.Player.GetLicenseIdentifier(source) -- license2 preferred; license fallback
```

## v1.2.0 additions

`DT.Alert` now supports Lation and native confirmation fallback.
`DT.ListMenu.Register/Show/Open/Close/SetOptions/GetOpen` provide keyboard list menus.
`DT.Ecosystem.List/Provider/Get/Call/Status/Utility` expose DTlib provider adapters.
Provider namespaces: Banking, Fuel, VehicleKey, Phone, Doorlock, Dispatch,
Clothing, Housing, Shops, Skills, BossMenu, Dialogue, Zones.
See [ECOSYSTEM.md](ECOSYSTEM.md) for signatures and examples.

## Callback lifecycle — beta.4

DTConfig.CallbackTimeout defaults to 30000 milliseconds. Await/AwaitClient raise callback_timeout when the other side does not reply, and release pending requests on the owning resource stopping or target player disconnecting. Existing success/error contracts remain. Callback arguments and return values preserve leading/trailing nil slots. Register callbacks again after restarting their consumer resource.

## Delta banner notifications — beta.7

Client: `DT.NotifyBanner(data)` or `exports.DTlib:NotifyBanner(data)`. Server: `DT.NotifyBanner(source, data)`. The banner always uses DTlib native NUI; ordinary `DT.Notify` keeps its configured provider. `DT.Notify({layout='banner', ...})` works too, including NotifyAll/NotifyPlayers.

```lua
DT.NotifyBanner({
    title = 'PROTECTION ACTIVE',
    subtitle = 'Lorazin',
    description = 'Poison resistance is active for 10 minutes.',
    image = 'nui://ox_inventory/web/images/lorazin.png',
    type = 'success', duration = 6500, position = 'top-right',
    progress = true, id = 'lorazin-protection'
})
```

Use `icon='fa-solid fa-shield-halved'` instead of image. Images accept HTTPS, nui://, or local relative paths; GTA CHAR_* texture names are not image URLs. `subject` aliases subtitle. No raw HTML is rendered. Duration is clamped to 250–86400000 ms in native UI (zero uses the default duration; use persistent=true for an untimed card). Positions: top-left, top, top-right, center-left, center-right, bottom-left, bottom, bottom-right; Bulletin-style topleft/topright/bottomleft/bottomright aliases are accepted. `progress=false` hides the lifetime bar; `stack=false` disables duplicate stacking. `DTConfig.UI.notifyMaxVisible` controls 1–8 cards per position (default 5); overflow queues up to 50 per position. Matching IDs update active/queued cards and restart visible lifetime. Duplicate messages stack with a count and refreshed lifetime. UI suspension discards notifications and clears timers/queues. No Bulletin export emulation or notification audio is added.

Banner countdown displays minutes/seconds by default; set countdown=false to hide it. Re-send DT.NotifyBanner with the same id to replace content and refresh its duration. Remove it with DT.RemoveNotifyBanner(id) on client, or DT.RemoveNotifyBanner(source,id) on server. persistent=true leaves the card visible until explicitly removed or UI suspension. Protection/pill authority and persistence belong to the consumer script, not the UI.


## Central admin hub — beta.9

Open `/dtlib:admin` to display registered, running-resource panels. DTlib checks the caller with `DT.Security.RequireAdmin` on the server and rate-limits hub requests. Existing panels retain their own authorization checks.

Register from each consumer's **client script** after DTlib starts:

```lua
exports.DTlib:RegisterAdminTool({
    id = 'zombies',
    label = 'Zombie Admin',
    description = 'Manage zombie settings and zones',
    command = 'zombies:admin' -- command without leading slash
})
```

The registered command must be a client command that opens that resource's existing admin UI. `id` is unique per resource registry; `label` and `description` are shown in the hub. The entry appears only while its registering resource is started. Use `exports.DTlib:UnregisterAdminTool('zombies')` when needed. Register each script's existing panel command; the hub does not discover arbitrary UIs automatically. Keep every panel's own server-side admin checks.


## Admin ACE groups — beta.10

DTlib accepts ACE object `admin` or `god` by default. Configure `adminAce` and `godAce` in `DTConfig.Security` if needed. Assign server principals in `server.cfg`; see the Security section above. `DT.Security.IsAdmin(source, ace)` with an explicit ACE checks that exact ACE object.

## beta.11 additions

See [BETA11.md](BETA11.md) for inventory `GetCatalog`, `GetItemImage`, `Supports`,
`RegisterUsableItem`, database `AwaitReady`, consumer readiness/rebinding,
restart-aware `DT.Admin.RegisterTool`, Discord failure handling and banner expiry.
It also documents the changed unsupported `CanCarry` result and upgrade limits.
