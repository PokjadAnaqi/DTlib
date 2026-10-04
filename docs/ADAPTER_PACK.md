# Full provider source pack — beta.2

All 153 provider profiles in 22 categories are included with their real client/server/shared module sources, plus every upstream runtime library, locale and dialogue web file. docs/IMPORTED_FILES.json lists every source path; docs/ADAPTER_SOURCES.json gives exact provider paths and side availability. Optional vendor resources must still be installed and started separately.

DT.Ecosystem retains the existing DTlib contracts and adds missing source-pack methods. Use DT.AdapterPack when you need the complete original provider signatures, rather than DTlib's normalized contracts:

```lua
local inventory, reason = DT.AdapterPack.Get('inventory', 'ox_inventory')
if inventory then inventory.AddItem(source, 'water', 1) end
local raycast, reason = DT.Ecosystem.Utility('Raycast')
local tables = DT.Ecosystem.Utility('Tables')
```

Provider selection uses DTConfig.Ecosystem.providers and DTConfig.Adapters. The full pack selects one provider per category on each runtime side; restart DTlib and its consumers after changing selection. Client-only and server-only methods follow the matrix. A stopped resource cannot be selected. DTlib APIs and imported APIs can differ in argument order: inspect the selected source module before using AdapterPack methods.

Utilities: Ids, Tables, Prints, Math, LA, Version, Callback, SQL, Logs, Scaleform, Placeable, PlaceableObject, Utility, Raycast, Point, Particle, Anim, Cutscene, Vehicles, Entity, Marker and Shell. Wrong-side requests return wrong_runtime_side. Language is available through DT.AdapterPack.Language.Locale.

DTlib keeps the Lation alert, notify, text UI, stepped progress, input, context menu and list menu implementations, plus okok integrations. No community_bridge exports or dependency is used. GPL source notices remain because imported code retains its original authorship.
