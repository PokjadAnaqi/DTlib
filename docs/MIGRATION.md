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

## 1.3.0-beta.1

Keep existing DT APIs and `@DTlib/init.lua`. Restart DTlib and consumers after replacing the resource folder.

- `DT.Ecosystem.Require` now accepts a DT utility name, not a Lua file path. Legacy helper namespaces `Language` and `VersionChecker` are removed; use your resource's localization and release management.
- Check `DT.Ecosystem.Supports(category, method, resource)` before optional operations. Unsupported/no-op vendor methods are omitted.
- `List.methods` returns current-side callable methods. Provider metadata includes separate client/server method arrays.
- Native skill XP is now session-only. Use a persistent skill resource or your own persistence integration before adopting native skills for saved progression.
- Clothing snapshots are normalized component/prop data on native/QB/ESX profiles; appearance profiles retain full vendor data. Use the vendor's save interface except ESX `Save`.
- Dialogue uses DT.Menu. Native zones use DT.Zone geometry under the compatibility profiles.
- Server phone mail treats the email argument as sender and sends to the target player's mailbox. Client callers can mail only themselves.
- Plate migration touches legacy inventory table names and invokes applicable vendor exports. Verify the schema of your installed version.

## 1.3.0-beta.2

The full source pack is bundled locally again. DTlib remains the only bridge resource to start. Full source signatures are under `DT.AdapterPack`, uppercase source utility names are accepted by `DT.Ecosystem.Utility`, and Language/VersionChecker helpers are available again. DT.Ecosystem.Require continues accepting utility names; path-based loading is explicit through DT.AdapterPack.Require. Restart DTlib and consumers after configuring providers.
