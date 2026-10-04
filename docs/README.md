# DTlib v1.2.0

DTlib is the unified runtime library for DT ecosystem FiveM resources. DT resources should depend on DTlib and call the `DT.*` API instead of importing third-party libraries directly.

## Goal

DT resource -> DTlib -> detected backend.

This keeps DT scripts stable when framework, inventory, target, database, weather, or UI backends are changed.

## Installation

1. Place the folder as `DTlib` in your resources directory.
2. Ensure it before all DT ecosystem resources.
3. In each DT resource add:

```lua
shared_scripts {
    '@DTlib/init.lua',
    'shared/*.lua'
}

dependency 'DTlib'
```

Do not include `@ox_lib/init.lua` in a DT resource merely for generic callbacks, notify, progress, menus, input, TextUI, or zones; DTlib provides those facilities itself.

## Recommended server.cfg

DTlib no longer requires any `dtlib_*` convars. Keep runtime configuration inside `settings/sharedConfig.lua`.

```cfg
# Optional UI/backend resources first, then DTlib.
ensure lation_ui
ensure DTlib

# Shared DT ecosystem Discord integration - the only convars DTlib reads.
set dt_eco_discord_bot_token "YOUR_BOT_TOKEN"
set dt_eco_discord_guild_id "YOUR_GUILD_ID"
```

Core adapter selection now lives in `settings/sharedConfig.lua`:

```lua
DTConfig.Debug = false
DTConfig.Strict = false

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

If `lation_ui` is not installed, omit its `ensure`; `DTConfig.Adapters.ui = 'auto'` will try `ox_lib` when it is running, then fall back to the DTlib native UI.

Never hardcode the Discord bot token in a resource.

## V1 backends

Framework: QBox/QBX, QBCore, ESX Legacy, ox_core, standalone fallback.
Inventory: ox_inventory/DT Grid Inventory, qb-inventory, framework fallback.
Target: ox_target, qb-target.
Database: oxmysql and ghmattimysql.
Weather: Renewed-Weathersync GlobalState, qb-weathersync, native fallback.
UI: Lation Modern UI (`lation_ui`), ox_lib Interface, and DTlib native NUI fallback.
Placement: `DT.Placement` defaults to DTlib's native direct `DrawGizmo` profile restored from v1.0.6 for precise X/Y/Z dragging. Official `object_gizmo` v3 remains an optional provider when explicitly selected. Native placement also freezes the player PED, supports object-centred `LMB DRAG` camera orbit + wheel zoom, and restores gameplay HUD overlays after confirm/cancel.

DT Grid Inventory remains compatible because it retains the `ox_inventory` resource/API identity.

## Notifications

v1.2.0 keeps notification handling into provider modules under `modules/notify/`. Client and server DT resources keep calling the same `DT.Notify` abstraction while DTlib selects Lation UI, ox_lib, okokNotify, or the native renderer.

See `docs/NOTIFY.md` and `docs/LATION_UI.md`.

## Server console status

Use `dtlib:status` from the server console to print the active DTlib runtime adapters and configuration state, including the UI backend. See `docs/CONSOLE_LOG.md`.


## Prop placement

DTlib provides a client-side entity/prop placement abstraction. DT resources should use `DT.Placement` / `DT.PropPlacement` instead of bundling their own placement controller.

```lua
local result = DT.Placement.PlaceProp(`prop_tool_bench02`, {
    distanceLimit = 8.0,
    snapToGround = true,
    freezeAfter = true,
})

if result.confirmed then
    print(result.coords, result.rotation, result.heading)
end
```

See `docs/PLACEMENT.md`.

- `WAYPOINTS.md` — native DT 3D waypoint module, sync API, UI and configuration.

## DT Waypoint

DTlib v1.0.8 adds the native `DT.Waypoint` system for local and server-synchronized 3D navigation markers. The module has its own DT Ecosystem DUI, lazy DUI pooling, map-waypoint mirroring and a master `enabled = true/false` configuration. See `WAYPOINTS.md`.


## UI provider priority (v1.0.9)
`DTConfig.Adapters.ui = 'auto'` prefers `lation_ui`, then `ox_lib`, then DTlib native UI. `ox_lib` support is optional and is not a mandatory DTlib dependency. Placement TextUI is rendered vertically on all providers.

- `MINIGAMES.md` - DTlib minigame wrappers: Lation Skill Check / Signal Breach / Pattern Lock with ox_lib Skill Check fallback.

- `UI_SUSPEND.md` - central temporary HUD/UI suspension lifecycle used by placement.

- `OX_SUPPORT.md` — official OX adapter coverage for ox_target, ox_inventory, ox_lib, and oxmysql.


## Framework / FiveM adapters

- `FRAMEWORK_SUPPORT.md` — Qbox, QB-Core, ESX Legacy, and ox_core adapter API.
- `FIVEM_SUPPORT.md` — state bags, routing buckets, identifiers, ACE, OneSync, and entity helpers.


## Architecture

See `ARCHITECTURE.md` for the v1.1 provider/module layout.

## v1.2.0 ecosystem expansion

See [ECOSYSTEM.md](ECOSYSTEM.md) for Lation Alert/List Menu, per-module UI settings,
okok providers, DTlib adapters and installation details.
See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) for all provider categories.
