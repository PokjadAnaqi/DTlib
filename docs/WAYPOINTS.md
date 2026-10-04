# DT Waypoint

DT Waypoint is the native 3D navigation marker module included in DTlib. It is implemented by DT Ecosystem and does not require `sleepless_waypoints`, `ox_lib`, or another waypoint resource.

The feature set was designed after reviewing common FiveM 3D waypoint patterns, including Sleepless Development's public waypoint resource: local markers, server-synced markers, DUI reuse, distance scaling, map waypoint mirroring, icons/images, and automatic removal by proximity. DTlib uses its own implementation and DT Ecosystem UI.

## Enable / disable

Edit `shared/config.lua`:

```lua
DTConfig.Waypoint = {
    enabled = true, -- false disables the entire waypoint module
    syncMapWaypoint = true,
    -- ...
}
```

The feature can also be overridden from `server.cfg`:

```cfg
DTConfig.Waypoint.enabled = true
DTConfig.Waypoint.syncMapWaypoint = true
```

## Client API

```lua
local id = DT.Waypoint.Create({
    coords = vec3(215.8, -810.2, 30.7),
    type = 'objective', -- objective | checkpoint | small | danger
    label = 'SUPPLY CACHE',
    subtitle = 'DT NAVIGATION',
    color = '#9db34f',
    icon = 'fa-solid fa-box-open',
    size = 1.0,
    displayDistance = true,
    drawDistance = 500.0,
    fadeDistance = 420.0,
    removeDistance = 2.0,
    pulse = true,
})

DT.Waypoint.Update(id, { label = 'CACHE SECURED', color = '#72a6c9' })
DT.Waypoint.Remove(id)
DT.Waypoint.RemoveAll('local')
```

Additional client functions:

```lua
DT.Waypoint.Enabled()
DT.Waypoint.Get(id)
DT.Waypoint.GetAll()
DT.Waypoint.SetMapSync(true)
DT.Waypoint.GetMapSync()
```

## Server synced API

```lua
local serverId = DT.Waypoint.Create(source, {
    coords = vec3(215.8, -810.2, 30.7),
    type = 'checkpoint',
    label = 'MISSION OBJECTIVE',
    color = '#9db34f',
    icon = 'fa-solid fa-crosshairs',
    removeDistance = 3.0,
})
```

Targets may be a player server ID, a list of IDs, or `-1` for every connected player.

```lua
DT.Waypoint.Update(serverId, { label = 'OBJECTIVE UPDATED' })
DT.Waypoint.Remove(serverId)
DT.Waypoint.RemoveAll(source)
DT.Waypoint.Get(serverId)
DT.Waypoint.GetAll()
DT.Waypoint.GetForPlayer(source)
```

Server waypoints are re-synchronized when the player's DTlib client starts. Player-specific waypoints are cleaned when the target disconnects. Global `-1` waypoints remain available for other players.

## UI

The DUI is a DT Ecosystem dark tactical navigation card built with Space Grotesk. It supports:

- `objective`, `checkpoint`, `small`, and `danger` styles
- configurable accent color
- Font Awesome class names
- image or URL icons
- label and subtitle
- live distance readout
- pulse mode
- distance fade and perspective scaling
- lazy DUI allocation with pooling and `maxVisible` cap

## Direct exports

For resources that do not import `@DTlib/init.lua`, DTlib also exposes `CreateWaypoint`, `UpdateWaypoint`, `RemoveWaypoint`, `RemoveAllWaypoints`, `GetWaypoint`, and `GetWaypoints`. Importing DTlib and using `DT.Waypoint.*` remains the recommended DT ecosystem pattern.


## Troubleshooting / Render Test
Run the following command client-side while in game:

```text
dtlib:waypoint:test
```

It spawns a DT waypoint roughly 8 metres in front of the player. If this marker appears, the renderer and DUI pipeline are working and the issue is with the coordinates/data supplied by the consuming resource. v1.0.11 also fixes billboard back-face culling and resolves GTA map-waypoint `z=0` values with a ground/player-elevation fallback.


## v1.0.13 render reliability

DTlib now waits for the local DUI page to explicitly report ready before assigning it to a waypoint. The local page uses the `nui://DTlib/html/waypoint.html` path and a 512x1024 canvas. The renderer draws both polygon windings to avoid camera-dependent back-face culling. If DUI creation/handshake fails, an optional native marker fallback is drawn so the target remains visible while diagnostics are available.

Relevant config:

```lua
DTConfig.Waypoint.dui.readyTimeout = 5000
DTConfig.Waypoint.fallback.enabled = true
```

Client diagnostic command:

```text
dtlib:waypoint:test
```


## v1.0.14 renderer diagnostics

Default renderer is now `sprite`, a DUI texture drawn with `DrawSprite` at a screen coordinate projected from the waypoint world coordinate. This avoids `DrawTexturedPoly` back-face/camera issues.

```lua
DTConfig.Waypoint.rendering.mode = 'sprite' -- recommended
-- DTConfig.Waypoint.rendering.mode = 'world' -- legacy world-poly
```

Test world anchoring with `dtlib:waypoint:test`. Test DUI independently of world projection with `dtlib:waypoint:dui`; it draws the waypoint NUI at the center of the screen for eight seconds.
