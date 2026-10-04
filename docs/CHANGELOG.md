# v1.2.0 — LATION / OKOK / COMMUNITY ECOSYSTEM

- Uses the uploaded v1.1.1 config-only build as baseline.
- Adds Lation Alert with close/result/labels/callouts support.
- Adds keyboard List Menu registration, show/hide, live updates, checks and side-scroll callbacks.
- Keeps Lation Notify, TextUI, Input, Context Menu, minigames and Progress with steps.
- Adds independent per-module UI provider settings and await-safe UI consumer bridges.
- Adds okokTextUI; integrates okokBanking, okokGarage keys, okokGasStation and okokPhone.
- Bundles 22 community adapter categories / 153 provider directories without requiring community_bridge.
- Adds new DT ecosystem namespaces, extra inventory adapters, optional sleepless_interact, language and utilities.
- Isolates adapter events/state and uses the existing DT callback/database transport.
- Keeps native placement/waypoint and Discord config-only settings.
- Includes full support matrix, API examples, pinned source notices and GPL source/license.
- Validated with Lua compilation, manifest checks and mocked provider/API contracts; live FiveM testing still required.

# DTlib Changelog

## 1.1.1 - Config-Only Runtime Settings

- Removed all active `dtlib_*` convar reads from DTlib.
- Framework, inventory, target, database, weather, UI, notify, console, placement, waypoint, minigame, debug and strict settings now live in `settings/sharedConfig.lua`.
- `settings/clientConfig.lua` and `settings/serverConfig.lua` remain available for client/server-specific settings.
- The only convars DTlib intentionally reads are `dt_eco_discord_bot_token` and `dt_eco_discord_guild_id`.
- OneSync helper capability detection no longer reads the `onesync` convar.


## 1.1.0 - Modular Bridge Architecture

- Rebuilt DTlib into provider-specific modules inspired by community bridge layouts.
- Framework adapters split into QBox, QB-Core, ESX, ox_core and standalone modules.
- Inventory adapters split into ox_inventory, qb-inventory and framework fallback modules.
- Target adapters split into ox_target and qb-target modules.
- Notify adapters split into Lation UI, ox_lib, okokNotify and native DTlib modules.
- Progress, TextUI/helptext, menu, input, alert, database, weather and minigame providers are now modular.
- Added shared module registry/selector while preserving the public `DT.*` API.
- Historical: v1.1.0 introduced a `dtlib_notify` adapter convar; v1.1.1 removed active `dtlib_*` convar usage.
- Placement now hard-locks all PAD input groups while active, including LMB/RMB and every PED gameplay key, while gizmo/camera controls read registered mappings and disabled-control state.
- Player PED remains frozen for placement and restores its previous frozen state on confirm/cancel.
- `fx_version 'cerulean'` remains unchanged.

## 1.0.28

- Added a hard placement PED input lock on both Lua and JS sides.
- Placement now disables movement/combat/reload controls on PAD groups 0, 1 and 2 every frame while the editor is active.
- Re-applies PED freeze and zero velocity every placement frame so editor hotkeys cannot create melee lunge/movement.
- `R` rotate can no longer leak into reload/melee; any transition-frame combat task is cleared immediately.
- Tracks every PED handle frozen during a placement session and restores each PED's original freeze state on confirm, cancel, resource stop, or cleanup.
- Preserves v1.0.6 direct DrawGizmo prop movement, object-camera LMB drag, wheel zoom, UI lifecycle restore, and ESC pause-menu suppression.

## 1.0.27

- Changed placement control label from `LMB EMPTY DRAG` to `LMB DRAG`.
- Fixed native object-camera wheel zoom by reading FiveM controls 14/15 plus cursor-scroll 241/242 and consuming those controls during placement.
- Player PED now freezes automatically for the full placement editor lifecycle and restores its previous freeze state on confirm/cancel/cleanup.
- Hardened melee/gameplay blocking so the `R` rotate key cannot make the PED punch behind the placement editor.
- Fixed HUD/temperature/radiation/quest UI remaining hidden after placement by removing the double restore path.
- Toggle-style visibility exports are now inverted exactly once; delayed restore retries only use idempotent setters/events.
- Removed the one-way `HideQuestNUI` placement fallback so quest tracker hiding is always reversible.
- Hardened ESC cancellation by deferring `LeaveCursorMode()` until ESC is released and keeping frontend pause controls blocked for a short post-release grace period.
- Preserved the v1.0.6 direct DrawGizmo prop transform path and object-centred LMB camera orbit.

## 1.0.26

- Restored v1.0.6 direct prop transform path as-is for native placement.
- Added LMB empty-space object-orbit camera without applying translation multipliers or smoothing to prop movement.
- Added wheel zoom around the edited object.
- Added grab/grabbing cursor states for camera interaction instead of a permanent mouse arrow.
- Kept v1.0.25 HUD restore retry and ESC pause-menu suppression fixes.


## v1.0.25 — v1.0.6 Direct Gizmo Drag Restore

- Restored the native placement manipulation profile from DTlib v1.0.6 as the default placement engine.
- `DrawGizmo` transform matrices are again applied directly 1:1 to props/entities with no custom translation multiplier, speed cap, interpolation, smoothing, or cursor recentering.
- Removed native LMB orbit interception from the default DTlib gizmo path so X/Y/Z handle dragging keeps the same responsive feel as v1.0.6.
- Added native grab/drag cursor sprite during placement (`SetMouseCursorSprite(4)`) and restore to the normal cursor on close.
- Kept ESC pause-menu suppression through key release.
- Kept placement HUD/UI suspension and recovery from newer builds.
- `object_gizmo` v3 support remains available but is no longer automatically preferred; DTlib native placement is the default.
- `object_gizmo` can still be selected explicitly for a placement call when its orbit/Three.js behaviour is wanted.

## v1.0.24 — Official object_gizmo v3 Placement Provider

- Integrated official `object_gizmo` v3 as DTlib's preferred automatic placement provider when the resource is running.
- DT resources still call only `DT.Placement.*`; no resource-local `object_gizmo` calls are required.
- Mirrored v3 defaults: orbit camera, centre pivot, direct TransformControls manipulation, world space, 0.5 gizmo size, standard snap values, wheel zoom, and LMB empty-space orbit.
- Removed DTlib translation multiplier/rate-cap tuning from the native fallback; no Shift/fine-drag mode remains.
- Added `DT.Placement.Provider()` and placement provider reporting in `dtlib:status`.
- Added v3-aware Cancel/Confirm routing through the official provider exports.
- Preserved DTlib `onChange` behaviour with a lightweight external-provider transform watcher.
- Added Lation TextUI bridge that suppresses duplicate ox_lib placement TextUI when Lation is active and `sleepless_prompts` is not running.
- Hardened placement HUD recovery by force-clearing stale placement suspension tokens and re-applying external UI state for up to three seconds after close.
- Kept GTA pause controls consumed through ESC release so cancelling placement cannot immediately open the pause menu.
- Native DTlib `DrawGizmo` remains an optional fallback; `object_gizmo` is not a mandatory DTlib dependency.

## v1.0.23 — Placement Precision + UI Recovery

- Removed Shift + drag fine movement from prop placement.
- Retuned normal translation to a much slower precision multiplier (`0.075`).
- Added frame-rate-independent translation speed cap (`0.55 m/s`) to prevent fast prop jumps on high-refresh clients.
- Retuned prop orbit camera sensitivity and added smooth prop-follow/zoom interpolation.
- Fixed ESC cancel opening the GTA pause menu by consuming frontend pause controls until ESC is released.
- Hardened placement cleanup with a stable Lua session reference.
- Added placement-specific UI recovery fallback and delayed restore retries after confirm/cancel.
- Removed `/tracker` toggle fallback from temporary quest hiding so placement never mutates the player's persistent tracker preference.
- Preserved DT Waypoint, DT Notify, DT TextUI, DT Progress, DT Menu and DT Input during placement.
- Preserved all v1.0.22 framework/FiveM API updates.

## v1.0.22 — Framework + FiveM Official API Update

- Added official `ox_core` framework adapter support without making ox_core a mandatory dependency.
- Updated Qbox integration to current `qbx_core` exports for jobs, gangs, groups, metadata, money, duty, and player lookup.
- Updated ESX integration to prefer `ESX.Player` / `ESX.ExtendedPlayers` and current account-based money APIs.
- Added normalized framework APIs for jobs, gangs, groups, vehicles, weapons, player lookup, money, metadata, status, and save operations.
- Added FiveM/Cfx state-bag helpers through `DT.State`.
- Added OneSync routing-bucket helpers through `DT.Routing`.
- Added entity/network-id helpers through `DT.Entity`.
- Added server ACE helper through `DT.Ace`.
- Added player identifier parsing helpers based on FiveM identifier APIs, including `GetLicenseIdentifier()` with `license2` preference and `license` fallback.
- Added server-side `CreateVehicleServerSetter` wrapper through `DT.OneSync.CreateVehicle`.
- Added `docs/FRAMEWORK_SUPPORT.md` and `docs/FIVEM_SUPPORT.md`.
- Preserved all v1.0.21 OX inventory/target/lib/mysql support and v1.0.20 placement UI behavior.

# DTlib v1.0.21 - OX OFFICIAL API UPDATE

+ Expanded ox_target TargetOption mapping, global targets, local/network entities, models, and zone management.
+ Added client-side ox_inventory abstraction for open/use/search/slot/weapon/weight/state APIs.
+ Expanded server-side ox_inventory abstraction for carry, slot, inventory, stash, drop, metadata, durability, admin, and registry APIs.
+ Added ox_lib notify, progress bar/circle, context menu, input dialog, alert dialog, and Skill Check integration through DTlib.
+ Added oxmysql `Prepare`, `RawExecute`, and expanded query helper parity.
+ Added `docs/OX_SUPPORT.md` with migration examples and supported DT APIs.
= DT resources continue to call only `DT.*`; OX resources remain optional backends.
= `dtlib_ui auto` continues to prefer Lation, then ox_lib, then native DTlib UI.
= Signal Breach and Pattern Lock remain Lation-only; ox_lib can provide Skill Check when Lation is unavailable.
= Preserved all v1.0.20 placement UI scope behaviour, waypoint rendering, prop orbit camera, and existing adapters.

# DTlib v1.0.20

- Placement UI suspension scope narrowed to external/gameplay overlays only.
- DT Waypoint continues rendering during placement.
- DT Notify, TextUI, Progress, Menu, and Input continue operating during placement.
- HUD, temperature, radiation, quest tracker, and registered external overlay integrations remain temporarily hidden and are restored after confirm/cancel.

# DTlib v1.0.19

- Added central external gameplay UI suspension lifecycle around prop placement.
- Added placement precision tuning with slower default translation and fine movement.
- Improved prop orbit mouse-wheel zoom handling.
- Added temporary HUD integration hooks for placement start/finish.

# DTlib v1.0.18

- Reworked placement camera to a prop-centred scripted orbit camera by default.
- LMB drag on empty space now orbits around the placed prop; LMB on gizmo axes continues to manipulate the gizmo.
- Mouse wheel zooms the prop camera.
- Camera pivot follows the prop while it is translated/rotated.
- Removed RMB gameplay-camera drag as the default placement camera behaviour.
- No server.cfg/convar is required for the orbit camera.
- Added per-call optional camera tuning (`cameraDistance`, `cameraMinDistance`, `cameraMaxDistance`, `cameraSensitivity`, `cameraZoomStep`, `cameraFov`).
- `camera = 'gameplay'` remains an explicit per-call escape hatch.

# DTlib v1.0.17

- Improved DT Waypoint readability on bright/complex world backgrounds.
- Increased waypoint card size, label/subtitle/distance font sizes and font weight.
- Added stronger opaque tactical panel, border, shadow and accent contrast.
- Increased default sprite width and reduced distance-based shrinking.
- Kept DT ecosystem tactical style while prioritizing gameplay readability.

# DTlib v1.0.16

- Camera look during prop placement is now a built-in DTlib default and no longer requires any CFG/convar.
- Removed `DTConfig.Placement.cameraLook` and `dtlib_placement_camera_look` from global placement configuration.
- `DT.Placement.Edit()` / `PlaceProp()` automatically enable hold-RMB camera look when `cameraLook` is not specified.
- Individual placement calls can still explicitly use `cameraLook = false` when a locked camera is desired.
- Lation/ox_lib/native TextUI remains passive and visible while camera look is used.

# DTlib v1.0.15

- Fixed placement camera being locked while Lation TextUI help is visible.
- Root cause was DTlib gizmo input blocking LOOK_LR/LOOK_UD and keeping cursor mode active, not Lation TextUI itself.
- Added hold-RMB camera look during DTlib placement: hold Right Mouse to release the gizmo cursor and drag the gameplay camera; release to return to gizmo control.
- Added `DTConfig.Placement.cameraLook` and `dtlib_placement_camera_look` (default enabled).
- Placement TextUI now shows `RMB - Hold to Look / Drag Camera` when camera look is enabled.
- Kept player combat/movement input blocked during placement while allowing camera axes only during camera-look mode.

# DTlib v1.0.14

- Replaced the default waypoint world-poly renderer with reliable screen-space DUI sprites anchored to 3D world coordinates.
- Kept legacy DrawTexturedPoly renderer as `DTConfig.Waypoint.rendering.mode = 'world'`.
- Removed DUI ready callback as a hard rendering dependency; `IsDuiAvailable` now gates DUI creation.
- Added configure resend after assignment for late CEF listeners.
- Added missing `resolveMapWaypointZ()` implementation so GTA map waypoint sync no longer crashes.
- Added `dtlib:waypoint:dui` fixed-screen diagnostic command.
- Re-anchored DT waypoint UI locator to the bottom of the DUI canvas for accurate world anchoring.

# DTlib Changelog

## v1.0.13 - Waypoint DUI Lifecycle Fix

- Reworked DT Waypoint DUI lifecycle after validating behavior against Sleepless Waypoints v1.1.2.
- Changed local DUI URL to `nui://DTlib/html/waypoint.html`.
- Added an explicit DUI page-ready handshake before configuring/rendering markers.
- Added double-sided textured-poly rendering to eliminate back-face culling edge cases.
- Expanded on-screen detection to marker bounds instead of a single world point.
- Added native marker fallback when DUI initialization fails, so waypoint targets never become completely invisible.
- Increased waypoint DUI canvas to 512x1024 and added configurable `readyTimeout`.
- Kept DT ecosystem waypoint UI and all v1.0.12 minigame support.

## v1.0.12 - Lation Minigame Support
- Added `DT.Minigame.SkillCheck()` with preset/custom difficulty, sequential inputs, normal/compact size, active state, and cancellation.
- Added `DT.Minigame.SignalBreach()` with preset/custom difficulty, progression options, wrong-key failure mode, `onNode` relay, active state, and cancellation.
- Added `DT.Minigame.PatternLock()` with preset/custom difficulty, multi-stage sequences, active state, and cancellation.
- Added cross-resource minigame event bridge so long-running NUI minigames await safely through `@DTlib/init.lua`.
- Added `DT.SkillCheck`, `DT.SignalBreach`, and `DT.PatternLock` compatibility aliases.
- Historical: minigame convar overrides were added here; v1.1.1 removed them in favour of `DTConfig.Minigames`.
- Added minigame provider state to `DT.GetAdapters()` and `dtlib:status`.
- Added `docs/MINIGAMES.md`.
- Lation UI remains optional; no mandatory new dependency was introduced.

## v1.0.11 - Waypoint Renderer Fix
- Fixed DT Waypoint billboard winding so `DrawTexturedPoly` faces the camera instead of being back-face culled.
- Added map-waypoint Z resolution with ground probing and player-elevation fallback for GTA waypoint blips that report `z = 0`.
- Added client diagnostic command `dtlib:waypoint:test` to spawn a test waypoint 8 metres in front of the player.
- Preserved all v1.0.10 item-label notify and previous DTlib features.

## v1.0.10 - Inventory Label Notifications

- Added automatic registered-item label resolution for DT notifications.
- Internal item IDs such as `airdrop_breach_tool` are replaced with the configured inventory label before display.
- Added `DTConfig.UI.resolveItemLabels` / `dtlib_notify_item_labels` master toggle.
- Added server `DT.Inventory.GetItemData(item)` and `DT.Inventory.GetItemLabel(item)` registry helpers.
- Added server exports `GetItemData` and `GetItemLabel`.
- Added ox_inventory / DT Grid first-party lookup with QBX, QBCore, and ESX registry fallbacks.
- Added client-side ox_inventory/QBCore fallback so direct client notifications also avoid raw item IDs.
- Unknown identifiers remain unchanged; DTlib only replaces tokens that resolve to a real registered item.

## 1.0.9 - Vertical TextUI / Placement Controls
- Added Lation UI multi-option TextUI layout for DT placement controls.
- Added optional ox_lib TextUI backend support through exports with compact multiline/vertical styling.
- Reworked DTlib native TextUI fallback into a compact vertical control card.
- Placement help now uses structured control rows instead of one long horizontal string.
- Added `DT.UI.UsingOxLib()` and ox_lib auto-detection after lation_ui.

# DTlib v1.0.8 — DT WAYPOINT

+ Added native `DT.Waypoint` client and server module.
+ Added DT Ecosystem tactical 3D waypoint DUI using Space Grotesk.
+ Added local waypoints and server-synchronized waypoints.
+ Added lazy DUI pooling, live distance, perspective scaling, fade distance and proximity auto-remove.
+ Added Font Awesome/icon image support and `objective`, `checkpoint`, `small`, `danger` styles.
+ Added optional GTA map waypoint mirroring.
+ Added `DTConfig.Waypoint.enabled = true/false` and `syncMapWaypoint = true/false`.
+ Historical: waypoint convar overrides were added here; v1.1.1 removed them in favour of `DTConfig.Waypoint`.
+ Added waypoint state to `dtlib:status` and `DT.GetAdapters()`.
= Kept v1.0.7 numeric-string prop model hash compatibility for database/admin placement values.
= Waypoint implementation is native DTlib; no `sleepless_waypoints`, `ox_lib`, or `community_bridge` dependency.

# DTlib v1.0.7 - PROP MODEL HASH COMPATIBILITY

+ Added numeric-string model hash support to `DT.Placement.PlaceProp()`.
+ Admin/NUI values such as `"31071109"` are now treated as model hashes instead of being re-hashed as text.
= Improved DT ecosystem prop placement compatibility for database-driven admin tools.
= Preserved model-name support such as `prop_tool_bench02`.

# DTlib v1.0.6 - NATIVE PROP PLACEMENT / GIZMO

+ Added `DT.Placement` as the official DT ecosystem entity/prop placement API.
+ Added `DT.PropPlacement` compatibility alias.
+ Added `client/gizmo.js` native Cfx `DrawGizmo` runtime.
+ Added `client/placement.lua` lifecycle, prop spawning, model loading and result API.
+ Added translate, rotate, optional scale, local/world control, ground snap, confirm and cancel workflow.
+ Added distance limit, network-control request, outline, collision, freeze and restore-on-cancel options.
+ Added Lation/native DT TextUI placement help through the existing `DT.TextUI` abstraction.
+ Added placement callbacks/events and direct exports.
+ Historical: placement convars were added here; v1.1.1 removed them in favour of `DTConfig.Placement`.
= DT resources no longer need their own `cache.ped`-based prop placement module.
= `DemiAutomatic/object_gizmo` is a behavioural reference only; DTlib does not depend on or embed it.
= DTlib remains free of mandatory `ox_lib` and `object_gizmo` dependencies.

# DTlib v1.0.5

- Fixed cross-resource capability checks where Cfx function references returned by `GetObject()` were callable but reported as `table` instead of `function`.
- `@DTlib/init.lua` now recursively normalizes `__cfx_functionReference` values into local Lua closures.
- Fixes legacy DT bridges reporting `DT.Callback.Register unavailable` or `DT.Callback.Await unavailable` even while DTlib is running.
- No DT resource API changes required.

# DTlib Changelog

## v1.0.4 - Callback Funcref Compatibility

- Fixed `DT.Callback.Register()` rejecting Cfx/FiveM cross-resource function references.
- Server and client callback registration now accept normal Lua functions, `__cfx_functionReference` callables, and callable tables.
- Callback references are normalized into local closures before storage/invocation.
- Added `DT.Callback.Unregister(name)` on client and server.
- Updated `DTUtils.safeCall()` to support Cfx function references.
- Added `DTUtils.isFunctionRef()`, `DTUtils.isCallable()`, and `DTUtils.wrapCallable()`.
- Fixes repeated `callback function is required` errors when DT resources register callbacks through the DTlib exported object.

## v1.0.3 - LATION UI + NOTIFY MODULE

+ Historical: the Lation adapter initially used `dtlib_ui`; v1.1.1 now uses `DTConfig.Adapters.ui`.
+ Added `DT.UI.Name()` and `DT.UI.UsingLation()`
+ Added dedicated `client/notify.lua`
+ Added dedicated `server/notify.lua`
+ Added client `DT.Notify()` / `exports.DTlib:Notify()` with Lation Modern UI rendering and native fallback
+ Added server `DT.Notify(source, ...)`, `DT.NotifyAll(...)`, and `DT.NotifyPlayers(...)`
+ Added Lation notification support for info/warning/success/error, duration, position, size, FontAwesome icon, icon colors/animations, custom colors, ID dedupe/update, and sound table passthrough
+ Added Lation-backed `DT.Progress`, `DT.ProgressActive`, and `DT.ProgressCancel`
+ Added Lation-backed `DT.TextUI.Show`, `DT.TextUI.Hide`, and `DT.TextUI.IsOpen`
+ Added Lation-backed `DT.Menu.Open` / `DT.Menu.Close`
+ Added Lation-backed `DT.Input.Await` / `DT.Input.Close`
+ Added automatic DT input field mapping (`text` -> Lation `input`) and named result mapping
+ Added UI backend to `DT.GetAdapters()` and `dtlib:status`
+ Added runtime start/stop console monitoring for `lation_ui`
+ Added `docs/LATION_UI.md` and `docs/NOTIFY.md`
= Preserved DTlib native NUI as automatic fallback when Lation UI is not running
= Preserved DT ecosystem API so individual DT resources do not call Lation exports directly
- No mandatory `lation_ui` dependency; Lation remains an optional backend

## v1.0.2 - INIT IMPORT FIX

- Fixed `Failed to load script @DTlib/init.lua` when DT resources import DTlib.
- Added `init.lua` to the DTlib resource packfile through `fxmanifest.lua`.
- Keeps the resource folder name exactly `DTlib` so `@DTlib/init.lua` resolves correctly.
- Keeps `@DTlib/init.lua` as the standard shared import for all DT ecosystem resources.
- No changes required to DT resource API calls.

# DTlib v1.0.1

+ Added structured SERVER CONSOLE LOG system
+ Added startup runtime summary for framework, inventory, target, database, weather and Discord integration
+ Added `dtlib:status` console/admin command to print current runtime status without restarting DTlib
+ Added backend resource start/stop monitoring for supported adapters
+ Added configurable INFO, WARN, ERROR, AUDIT and DEBUG console levels
+ Added optional timestamps and production anti-spam console settings
+ Added `DT.Logger.GetRuntimeStatus()` and `DT.Logger.PrintStatus()`
+ Added `GetRuntimeStatus` and `PrintStatus` server exports
+ Added `docs/CONSOLE_LOG.md`
= Improved logger JSON payload safety
= Improved webhook failure reporting
= Changed server load order so logger initializes before runtime modules and bootstrap runs last
= Updated DTlib version to 1.0.1
- Discord bot token is never exposed in console output

# DTlib v1.0.0

+ Added unified DT ecosystem bootstrap via `@DTlib/init.lua`
+ Added automatic QBX/QBCore/ESX framework detection
+ Added unified player, money, metadata, job and gang API
+ Added ox_inventory / DT Grid Inventory and qb-inventory adapters
+ Added native DT callback system without ox_lib
+ Added native notify, progress, TextUI, menu and input NUI
+ Added native sphere, box and polygon zone system
+ Added ox_target and qb-target adapters
+ Added oxmysql/ghmattimysql database abstraction
+ Added Discord member, role and avatar helpers using DT ecosystem convars
+ Added server rate limiting and ACE admin helpers
+ Added logging and webhook helpers
+ Added vehicle helpers
+ Added Renewed-Weathersync / qb-weathersync weather reads with native fallback
+ Added migration and security documentation
- No dependency on community_bridge
- No mandatory dependency on ox_lib

