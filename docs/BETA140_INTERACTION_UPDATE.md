> Historical beta notes. The current standalone interaction setup is documented in STANDALONE_INTERACT.md.

# DTlib v1.4.0-beta.2 — Interact input update

Based on the published v1.4.0-beta.1 source at commit e8ce49fc40a02f6a29f2ac4de151e7adb121a69b. This package contains the TSX source and compiled runtime. It is a local beta build; it does not publish a GitHub release.

## Installation

Replace the DTlib folder with the fresh folder from this ZIP. Merge your existing settings rather than overwriting them blindly. Keep `fx_version 'cerulean'`.

In `settings/sharedConfig.lua`:

```lua
DTConfig.Interaction.mode = 'interact'
DTConfig.Interaction.key = 'E'
DTConfig.Interaction.cursorKey = 'LMENU' -- false disables cursor binding
```

Restart DTlib and resources registering interactions. Existing FiveM key bindings can be changed under Settings > Key Bindings > FiveM.

## Controls

- Approach and look at a valid target: a compact `[E] label` prompt appears.
- Tap E to expand its options. Use up/down arrows and E to choose/confirm.
- While the options are expanded, hold Left Alt and left-click to free the cursor. Click an option to execute it.
- Right-click or Escape returns control to the camera. Releasing Alt also releases the cursor.
- Successful selection collapses the list. The cursor releases before the action runs, allowing an inventory/menu to take focus.
- Target changes/loss, permission changes, progress, death, pause, UI suspension, disabling targeting and resource stop clear the interaction state.

DT colors and typography are retained. Opening, collapsing and hover transitions animate; reduced-motion preferences disable animation. Entity anchors use current entity coordinates every render frame.

## Icons

Font Awesome Free 6.7.2 CSS and fonts are bundled locally, including solid, regular and brands. No CDN is needed for those fonts. Pass `icon` and optional `iconColor` on each option. Sphere/box/poly registration `label` or `title` supplies the header. Otherwise the first option's `interactionLabel` or `label` supplies it.

```lua
DT.Target.AddGlobalPlayer({
    {
        name = 'my_trade',
        interactionLabel = 'Player Interaction',
        label = 'Offer Trade',
        icon = 'fa-solid fa-handshake',
        iconColor = '#b5c98f',
        distance = 2.0,
        onSelect = function(data)
            -- Hook up your existing trade action here.
        end
    }
})
```

## Scope and validation

Registrations must pass through DT.Target. Direct ox_target/qb-target exports are unchanged. Bones, offsets and nested target menus retain the beta.1 limitations. This update adds no Lation dependency and does not implement all Lation configuration/API features. Lation documentation and screenshots were behavior references only.

Click callbacks validate current generation, option identity, permissions, distance and target again. FiveM gameplay authorization must still be checked server-side by the consuming script.

Validation covers TypeScript/build, React prompt/icon/click/exit behavior, Lua cursor ownership/release, stale and malformed callbacks, authorization changes, target removal, geometry and existing regression suites. Live FiveM rendering/input conflicts still require an in-game test.

Validation results: 5 React tests passed; 13 Python suites and 3 Node suites passed; the contract suite compiled 374 Lua files and initialized 219 provider/side combinations. Browser screenshot validation was unavailable because the browser binary could not be downloaded in this environment.
