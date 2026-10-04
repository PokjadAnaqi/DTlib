# DTlib Placement / Gizmo

DTlib exposes one placement API for all DT ecosystem resources:

```lua
DT.Placement
DT.PropPlacement -- alias
```

## Provider behaviour in v1.1.1


The default provider is now `dtlib_gizmo`, using the direct native `DrawGizmo` manipulation profile restored from DTlib v1.0.6. The matrix returned by `DrawGizmo` is applied 1:1 to the entity: no translation sensitivity multiplier, smoothing, speed cap, cursor recentering, or LMB camera interception is applied.

`object_gizmo` v3 support remains available as an optional provider. Set `provider = 'object_gizmo'` on a placement call (or change the central DTlib placement provider) only when that external behaviour is desired.

While the native placement editor is active, DTlib changes the GTA/FiveM cursor to the grab/drag cursor sprite and restores the normal cursor when placement closes.

## Optional object_gizmo v3 provider

```cfg
ensure ox_lib
ensure object_gizmo
ensure lation_ui # optional DT UI provider
ensure DTlib
```

`object_gizmo` itself requires ox_lib. DTlib does not make `object_gizmo` mandatory because the native fallback remains available.

## Edit an existing entity

```lua
local result = DT.Placement.Edit(entity, {
    distanceLimit = 8.0,
    enableScale = false,
    snapToGround = true,
    freezeEntity = true,
    freezePlayer = true, -- default; prevents gameplay actions behind the editor
    restoreOnCancel = true,
})

if result.confirmed then
    print(result.coords)
    print(result.rotation)
    print(result.heading)
end
```

Aliases:

```lua
DT.Placement.Start(entity, options)
DT.Placement.UseGizmo(entity, options)
DT.PropPlacement.Edit(entity, options)
```

## Spawn and place a prop

```lua
local result = DT.Placement.PlaceProp('prop_tool_bench02', {
    forwardDistance = 2.0,
    distanceLimit = 8.0,
    snapToGround = true,
    deleteOnCancel = true,
    freezeAfter = true,
})
```

Model names, numeric hashes, and numeric hash strings are supported.

## Controls

Default native v1.0.6-style provider:

- LMB on a gizmo handle manipulates the prop directly.
- `W` selects translate mode.
- `R` selects rotate mode.
- `S` selects scale mode when scaling is enabled.
- `Q` toggles world/local space.
- `LALT` snaps to ground.
- `ENTER` confirms.
- `ESC` cancels/restores.
- The cursor uses the native grab/drag sprite while placement is active.

When `provider = 'object_gizmo'` is explicitly selected, its v3 empty-space orbit, wheel zoom, snap toggle, and copy-transform controls remain available.

There is no Shift/fine-drag modifier in DTlib v1.1.1. Native drag uses the direct v1.0.6 DrawGizmo path.

## Official v3 defaults mirrored by the adapter

```lua
{
    camera = 'orbit',
    mode = 'translate',
    space = 'world',
    pivot = 'center',
    gizmoSize = 0.5,

    snap = false,
    translationSnap = 0.25,
    rotationSnap = 15.0,
    scaleSnap = 0.1,

    orbit = {
        minRadius = 1.5,
        maxRadius = 25.0,
        zoomStep = 0.75,
        sensitivity = 0.005,
        blend = 250,
    }
}
```

Any of these can still be overridden for an individual `DT.Placement.Edit` / `PlaceProp` call.

## Placement UI lifecycle

Gameplay overlays are temporarily hidden while placement is active:

- GTA HUD/radar
- DT temperature UI
- DT radiation UI
- supported survival HUDs
- quest tracker
- DT resources listening to `DTlib:ui:suspend`

These continue to run normally during placement and are **not** suspended:

- DT Waypoint
- DT Notify
- DT TextUI used for placement controls
- DT Progress
- DT Menu
- DT Input

After confirm or cancel, DTlib clears stale placement suspension tokens and re-applies the previous HUD state several times while NUI/camera teardown finishes. This fixes overlays remaining hidden after placement.

## ESC / pause menu protection

DTlib blocks the GTA frontend pause controls for the placement lifecycle and keeps them consumed until the cancel key is released. This is layered on top of the v3 release-based close behaviour, preventing `ESC` from cancelling placement and opening the pause menu in the same keypress.

## Lation TextUI

When the v3 provider is active and DTlib is using Lation UI, DTlib keeps the vertical Lation placement control panel and suppresses the duplicate ox_lib TextUI panel from `object_gizmo` when `sleepless_prompts` is not running.

If `sleepless_prompts` is running, the official prompt strip is left untouched.

## Result

```lua
{
    entity = entity,
    handle = entity,
    confirmed = true|false,
    cancelled = true|false,
    reason = 'confirmed'|'cancelled'|'busy'|'entity_missing'|...,
    coords = vector3(...),
    position = vector3(...),
    rotation = vector3(...),
    heading = 0.0,
    limited = false,
}
```

## Global placement settings

No camera-look or Shift-drag CFG is required.

```cfg
DTConfig.Placement.distanceLimit = 8.0
DTConfig.Placement.showHelp = true
DTConfig.Placement.outline = true
DTConfig.Placement.freezeAfter = true
```

The built-in default provider is `dtlib_gizmo`. `object_gizmo` is optional and must be selected explicitly (for example with `provider = 'object_gizmo'`) if its v3 orbit behaviour is wanted.

## v1.0.28 native camera drag + lifecycle fixes

The default native provider keeps the v1.0.6 direct `DrawGizmo` matrix path for prop movement. Camera drag is handled separately so it does not scale or smooth the prop transform.

- LMB on X/Y/Z gizmo handle: direct prop transform (v1.0.6 behaviour)
- LMB drag away from an active gizmo handle: orbit camera around the edited object (UI label: `LMB DRAG`)
- Mouse wheel: zoom orbit camera using both FiveM wheel input paths (`14/15` and cursor scroll `241/242`)
- Idle placement cursor: grab cursor
- Active camera drag cursor: grabbing cursor
- Camera target follows the object after a prop drag, while staying stable during the gizmo drag itself

Native orbit defaults match the object-gizmo style interaction (`0.005` orbit sensitivity and `0.75` wheel step) while preserving DTlib's direct native prop manipulation. No Shift fine-movement modifier is used.


### v1.0.28 placement safety

- Player PED freezes automatically while placement controls are open, preventing `R`, movement, melee, reload, and other gameplay actions from firing behind the editor.
- PED freeze state is restored exactly to its pre-placement state after confirm, cancel, provider fallback, or DTlib stop.
- ESC cancellation keeps cursor mode and pause controls captured until ESC is physically released, then holds a short frontend guard before returning normal input. This prevents the GTA pause menu from opening on the same cancel keypress.
- HUD/UI restore no longer calls toggle-style exports multiple times. `ToggleVisible` integrations are reversed exactly once, while setter/event integrations can be safely retried.
- Quest placement hiding no longer calls the one-way `HideQuestNUI` fallback; only reversible temporary tracker suppression paths are used.
