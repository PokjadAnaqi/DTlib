# DTlib OX Integration

DTlib v1.0.21 expands the official OX adapters for `ox_target`, `ox_inventory`, `ox_lib`, and `oxmysql`.

DT ecosystem resources should continue to import only DTlib:

```lua
shared_scripts {
    '@DTlib/init.lua'
}

dependency 'DTlib'
```

Do not add direct OX calls to a DT resource when an equivalent `DT.*` API exists.

## Optional backend configuration

```cfg
DTConfig.Adapters.target = 'auto'
DTConfig.Adapters.inventory = 'auto'
DTConfig.Adapters.ui = 'auto'
DTConfig.Adapters.database = 'auto'
```

`auto` detects a supported running backend. OX resources remain optional; DTlib still supports its existing alternate/fallback adapters.

A typical OX-based start order is:

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core       # or the framework used by the server
ensure ox_target
ensure ox_inventory
ensure DTlib
```

## ox_target

DTlib passes through the important ox_target TargetOption fields:

```lua
DT.Target.AddModel(`prop_toolchest_05`, {
    {
        name = 'dt_open_toolbox',
        label = 'Open Toolbox',
        icon = 'fa-solid fa-toolbox',
        iconColor = '#9db34f',
        distance = 2.0,
        bones = {'chassis'},
        offset = vec3(0.0, 0.0, 0.2),
        offsetAbsolute = nil,
        offsetSize = 0.4,
        groups = {mechanic = 0},
        items = {toolkit = 1},
        anyItem = false,
        canInteract = function(entity, distance, coords, name, bone)
            return DoesEntityExist(entity)
        end,
        onSelect = function(data)
            print(data.entity)
        end
    }
})
```

Supported target APIs include:

```text
DT.Target.Disable / DisableTargeting
DT.Target.IsActive
DT.Target.GetOptions
DT.Target.AddGlobal / RemoveGlobal
DT.Target.AddGlobalObject / RemoveGlobalObject
DT.Target.AddGlobalPed / RemoveGlobalPed
DT.Target.AddGlobalPlayer / RemoveGlobalPlayer
DT.Target.AddGlobalVehicle / RemoveGlobalVehicle
DT.Target.AddEntity / AddLocalEntity
DT.Target.RemoveEntity / RemoveLocalEntity
DT.Target.AddNetworkEntity / RemoveNetworkEntity
DT.Target.AddModel / RemoveModel
DT.Target.AddSphereZone
DT.Target.AddBoxZone
DT.Target.AddPolyZone
DT.Target.ZoneExists
DT.Target.RemoveZone
```

## ox_inventory — client

`DT.Inventory.SetGetPlayerNameMethod(cb)` is also available for overriding the ox_inventory player display-name resolver through DTlib.

```lua
DT.Inventory.Open('stash', 'machine_01')
DT.Inventory.OpenStash('machine_01')
DT.Inventory.UseSlot(1)
DT.Inventory.GetCurrentWeapon()
DT.Inventory.GetCount('water')
DT.Inventory.HasItem('water', 2)
DT.Inventory.Search('slots', 'water')
DT.Inventory.GetItems()
DT.Inventory.GetWeight()
DT.Inventory.GetMaxWeight()
DT.Inventory.GetSlotWithItem('water')
DT.Inventory.SuppressItemNotifications(true)
```

DTlib also exposes helpers for inventory state bags:

```lua
DT.Inventory.IsBusy()
DT.Inventory.SetBusy(true)
DT.Inventory.IsOpen()
DT.Inventory.SetHotkeys(false)
DT.Inventory.SetCanUseWeapons(false)
DT.Inventory.SetInstance('mission_01')
```

## ox_inventory — server

`DT.Inventory.SetPlayerInventory(player, data)` is available for bridge-style player inventory initialization when ox_inventory is active.

Core item operations:

```lua
DT.Inventory.CanCarry(source, 'water', 5)
DT.Inventory.CanCarryAmount(source, 'water')
DT.Inventory.CanCarryWeight(source, 5000)
DT.Inventory.CanSwapItem(source, 'water', 1, 'bandage', 1)
DT.Inventory.AddItem(source, 'water', 2)
DT.Inventory.RemoveItem(source, 'water', 1)
DT.Inventory.GetItem(source, 'water')
DT.Inventory.GetCount(source, 'water')
DT.Inventory.Search(source, 'slots', 'water')
```

Slot/inventory APIs:

```text
DT.Inventory.GetItemSlots
DT.Inventory.GetSlot
DT.Inventory.GetSlotForItem
DT.Inventory.GetSlotIdWithItem
DT.Inventory.GetSlotIdsWithItem
DT.Inventory.GetSlotWithItem
DT.Inventory.GetSlotsWithItem
DT.Inventory.GetEmptySlot
DT.Inventory.GetContainerFromSlot
DT.Inventory.GetInventory
DT.Inventory.GetInventories
DT.Inventory.GetItems / GetInventoryItems
DT.Inventory.SetMaxWeight
DT.Inventory.SetSlotCount
DT.Inventory.SetMetadata
DT.Inventory.SetDurability
DT.Inventory.GetCurrentWeapon
```

Storage/drop/admin APIs:

```text
DT.Inventory.RegisterStash
DT.Inventory.CreateTemporaryStash
DT.Inventory.CustomDrop
DT.Inventory.CreateDropFromPlayer
DT.Inventory.SetContainerProperties
DT.Inventory.Clear / ClearInventory
DT.Inventory.RemoveInventory
DT.Inventory.ForceOpen
DT.Inventory.OpenStash
DT.Inventory.UpdateVehicle
DT.Inventory.Inspect
DT.Inventory.Confiscate
DT.Inventory.Return
DT.Inventory.ConvertItems
```

Registry helpers remain available on client and server:

```lua
DT.Inventory.Items('water')
DT.Inventory.GetItemData('water')
DT.Inventory.GetItemLabel('water')
DT.Inventory.ClearItemCache('water')
```

## ox_lib

With `DTConfig.Adapters.ui = 'ox_lib'`, or when `auto` resolves to ox_lib, DTlib can route:

```text
DT.Notify
DT.Progress / DT.ProgressActive / DT.ProgressCancel
DT.TextUI.Show / Hide / IsOpen
DT.Menu.Open / Close
DT.Input.Await / Close
DT.Alert.Await / Close
```

Progress supports both bar and circle modes:

```lua
DT.Progress({
    duration = 3500,
    label = 'Processing...',
    circle = true,
    position = 'bottom',
    canCancel = true,
    disable = {combat = true}
})
```

Input fields accept ox_lib-compatible field definitions including input, number, checkbox, select, slider, color, multi-select, date, date-range, time, and textarea.

Alert dialog:

```lua
local result = DT.Alert.Await({
    header = 'Confirm Action',
    content = 'Continue with this operation?',
    cancel = true,
    centered = true,
    labels = {confirm = 'CONFIRM', cancel = 'CANCEL'}
})

if result == 'confirm' then
    -- confirmed
end
```

### Skill Check fallback

Lation remains the preferred provider when it is running. If Lation is unavailable and ox_lib is running, DTlib can use ox_lib for Skill Check:

```lua
local success = DT.Minigame.SkillCheck({
    difficulty = {'easy', 'medium', 'hard'},
    inputs = {'W', 'A', 'S', 'D'}
})
```

Signal Breach and Pattern Lock remain Lation-only because ox_lib does not provide equivalent components.

## oxmysql

DTlib exposes the standard result-shape helpers plus high-frequency query helpers:

```lua
local rows = DT.Database.Query(sql, params)
local row = DT.Database.Single(sql, params)
local value = DT.Database.Scalar(sql, params)
local insertId = DT.Database.Insert(sql, params)
local affected = DT.Database.Update(sql, params)
local result = DT.Database.Prepare(sql, params)
local result = DT.Database.RawExecute(sql, params)
local success = DT.Database.Transaction(queries, params)
```

Lower-camel aliases are also available:

```lua
DT.Database.query(...)
DT.Database.single(...)
DT.Database.scalar(...)
DT.Database.insert(...)
DT.Database.update(...)
DT.Database.prepare(...)
DT.Database.rawExecute(...)
DT.Database.transaction(...)
```
