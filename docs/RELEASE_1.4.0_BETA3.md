# DTlib v1.4.0-beta.3 — Idle resmon overhead

Based on published v1.4.0-beta.2. This patch targets unnecessary idle work inside DTlib.

- Register the JavaScript gizmo frame tick only when placement starts. Clear it after confirmation, cancellation/ESC guard completion, or resource stop. Avoid duplicate ticks when reopening or requesting a busy session.
- Keep frame-by-frame drawing/input while placement is active and keep the held-ESC pause guard until release.
- Skip camera reads, candidate table allocation and sorting in the waypoint visibility loop when there are no registered waypoints; check again after 500 ms. Existing waypoints retain the configured visibility update interval.
- Skip player-position native calls when there are no zones or none are due. All due zones share one position read per scan; existing callbacks and intervals are retained.
- Keep the standalone DT_interact adapter and beta 2 configuration unchanged. DT_interact is distributed separately and is not included in this package.

## Install

Download the compiled runtime ZIP. Replace the existing DTlib folder with the fresh DTlib folder, merge your settings and restart DTlib and its consumers. Keep `fx_version 'cerulean'`.

For the separately installed DT_interact backend:

```lua
DTConfig.Interaction.mode = 'target'
DTConfig.Adapters.target = 'DT_interact'
```

## Validation and resmon comparison

All 18 Python/Node regression suites pass, including Lua syntax/manifest/provider checks and new behavioral checks for idle ticks, confirm/cancel, held ESC, reopening, entity loss, resource stop, shared zone position reads and empty waypoint scanning.

These are simulated checks, not a live FiveM benchmark. No fixed ms or percentage improvement is claimed. To compare, record `resmon 1` for beta 2 and beta 3 on the same client/server with the same FPS cap, resources and gameplay state: idle with no placement/waypoints, active waypoint, then placement confirm and cancel. Check DTlib and DT_interact separately. If the spike remains, capture the profiler around the spike so the remaining hot path can be identified.

Editable source is on `release/1.4.0-beta.3`; the runtime ZIP excludes development dependencies, tests and native UI TSX source, and retains compiled UI assets.
