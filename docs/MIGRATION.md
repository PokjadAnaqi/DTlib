# DT Ecosystem Migration Guide

Migrate each DT resource independently. Do not replace every dependency in one deployment.

## 1. Manifest

Before:
```lua
shared_scripts { '@ox_lib/init.lua' }
```

After:
```lua
shared_scripts { '@DTlib/init.lua' }
dependency 'DTlib'
```

Keep true backend runtime dependencies only where the resource genuinely owns that backend. Normal DT resources should not directly depend on framework/bridge utility libraries.

## 2. UI helpers

```lua
lib.notify({...})             -> DT.Notify({...})
lib.progressBar({...})        -> DT.Progress({...})
lib.showTextUI(text)          -> DT.TextUI.Show(text)
lib.hideTextUI()              -> DT.TextUI.Hide()
lib.inputDialog(...)          -> DT.Input.Await({...})
lib.registerContext/open...   -> DT.Menu.Open({...})
```

## 3. Callbacks

```lua
lib.callback.register(name, cb) -> DT.Callback.Register(name, cb)
lib.callback.await(name, ...)   -> DT.Callback.Await(name, ...)
```

## 4. Framework

```lua
exports.qbx_core:GetPlayer(src) -> DT.Player.Get(src)
QBCore.Functions.GetPlayer(src) -> DT.Player.Get(src)
ESX.GetPlayerFromId(src)        -> DT.Player.Get(src)
```

Use DT player methods for identity, job/gang, metadata, and money.

## 5. Inventory

```lua
exports.ox_inventory:AddItem(...)    -> DT.Inventory.AddItem(...)
exports.ox_inventory:RemoveItem(...) -> DT.Inventory.RemoveItem(...)
exports.ox_inventory:GetItemCount(...) -> DT.Inventory.GetCount(...)
```

For DT Grid Inventory, DTlib sees the backend as `ox_inventory`.

## 6. Target

Replace direct `ox_target`/`qb-target` calls with `DT.Target.*`. This allows the backend to change without editing the DT resource.

## 7. Zones

Prefer native `DT.Zone.*` for non-target area detection. It has no ox_lib dependency.

## Suggested migration order

1. DT_temperature
2. DT_airdropsystem
3. DT_recyclesystem
4. DT_tradesystem
5. DT_skilltree
6. DT_classsystem
7. DT_questsystem
8. DT_donatesystem
9. remaining DT resources

Start with resources that already use simple notify/callback/target patterns. Validate each resource before moving to the next.
