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

Default admin ACE is `group.admin`.

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
