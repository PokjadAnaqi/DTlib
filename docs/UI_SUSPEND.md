# DTlib UI Suspend

DTlib uses a central external/gameplay UI suspension lifecycle automatically during prop placement.

When placement starts, DTlib temporarily hides gameplay HUD layers and supported DT ecosystem UIs, while keeping the placement controls TextUI visible. On confirm/cancel, the previous visibility state is restored where a visibility query is available.

State/event integration for other DT resources:

```lua
local hidden = LocalPlayer.state.dtlibUiSuspended == true

AddEventHandler('DTlib:ui:suspend', function(reason)
    -- temporarily hide persistent UI without changing saved player preference
end)

AddEventHandler('DTlib:ui:resume', function(reason)
    -- restore previous UI state
end)
```

Client API:

```lua
local token = DT.UI.Suspend('custom_scene')
DT.UI.Resume(token)
DT.UI.IsSuspended()
```

Prop placement uses this automatically unless a single placement explicitly sets `hideUI = false`.


## DTlib UI during placement

`DT.UI.Suspend('placement')` does **not** disable DTlib's own interactive UI stack. During placement these continue to operate normally:

- `DT.Waypoint`
- `DT.Notify`
- `DT.TextUI`
- `DT.Progress`
- `DT.Menu`
- `DT.Input`

The suspension lifecycle is intended for gameplay overlays such as HUD, temperature, radiation and quest tracker integrations.


## Placement restore safety (v1.0.27)

DTlib distinguishes idempotent visibility setters from toggle-style APIs. Toggle-style integrations such as `ToggleVisible` are called only once to hide and once to restore; delayed recovery passes only re-assert setter/event based visibility. This prevents a sequence of restore retries from toggling a HUD back off.

Placement also avoids one-way quest-hide calls and uses reversible tracker suppression events/exports only.
