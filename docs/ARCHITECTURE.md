# DTlib v1.1 Modular Architecture

DTlib v1.1 separates every backend adapter from the public `DT.*` API.
DT resources continue to import only `@DTlib/init.lua`; they never call framework,
inventory, target, UI, database, or notification resources directly.

## Layout

```text
DTlib/
├─ settings/
│  ├─ sharedConfig.lua
│  ├─ clientConfig.lua
│  └─ serverConfig.lua
├─ shared/
│  ├─ core.lua
│  └─ utils.lua
├─ lib/
│  ├─ modules/shared.lua
│  ├─ callback/{client,server}.lua
│  ├─ fivem/{client,server}.lua
│  ├─ logger/server.lua
│  ├─ security/server.lua
│  ├─ discord/server.lua
│  └─ vehicle/client.lua
└─ modules/
   ├─ framework/{qbx_core,qb-core,es_extended,ox_core,standalone}/
   ├─ inventory/{ox_inventory,qb-inventory,framework}/
   ├─ target/{ox_target,qb-target,none}/
   ├─ notify/{lation_ui,ox_lib,okokNotify,native}/
   ├─ progressbar/{lation_ui,ox_lib,native}/
   ├─ helptext/{lation_ui,ox_lib,native}/
   ├─ menu/{lation_ui,ox_lib,native}/
   ├─ input/{lation_ui,ox_lib,native}/
   ├─ alert/{ox_lib,native}/
   ├─ database/{oxmysql,ghmattimysql,none}/
   ├─ weather/{renewed,qb,native}/
   ├─ minigames/{lation_ui,ox_lib}/
   ├─ placement/dtlib/
   ├─ waypoint/dtlib/
   ├─ zones/
   ├─ ui_suspend/
   └─ bootstrap/
```

Each provider file registers only its own adapter. Router files such as
`modules/framework/server.lua` and `modules/inventory/client.lua` expose the
stable `DT.*` API and select the active adapter.

## Adapter selection

Adapters remain optional and are chosen automatically unless overridden with
server.cfg convars:

```cfg
DTConfig.Adapters = {
    framework = 'auto',
    inventory = 'auto',
    target = 'auto',
    database = 'auto',
    weather = 'auto',
    ui = 'auto',
    notify = 'auto'
}
```

This architecture is inspired by modular bridge projects, but DTlib keeps its
own API, implementation, placement system, waypoint system, security model and
runtime behavior.


## Placement input isolation

Native placement uses a full PAD lock while active. DTlib disables all GTA control actions for control groups 0-2 every frame, freezes the current player ped, blocks firing, and reads placement camera/gizmo inputs through disabled-control state/key mappings. This prevents LMB, RMB, movement, reload, melee, weapon-wheel and other gameplay actions from leaking to the ped. Original ped freeze state is restored when placement finishes.

## v1.2.0 ecosystem expansion

See [ECOSYSTEM.md](ECOSYSTEM.md) for Lation Alert/List Menu, per-module UI settings,
okok providers, embedded community adapters and installation details.
See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) for all provider categories.
