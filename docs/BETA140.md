# DTlib 1.4.0-beta.1

Native menu, input, TextUI and progress now render through React/TypeScript.
Sources are in html/src; html/dist is the built runtime loaded by fxmanifest.
The existing notification/banner engine, 300px sizing and dialogue/waypoint
renderers remain in this first beta. Provider-selected Lation/ox UI still uses
its own resource. Build with npm ci and npm run build inside html.

## E interaction (opt-in)

Set DTConfig.Interaction.mode = 'interact' in settings/sharedConfig.lua before
starting DTlib and its consumers. The default 'target' keeps your installed
ox_target/qb-target UI. Restart DTlib and consumers after changing modes.

In interact mode, registrations made through DT.Target use a DTlib React DUI
prompt anchored to the world. Look towards an eligible entity, approach, then
press E. Use up/down arrows for multiple options. The keyboard binding can be
changed under FiveM key bindings. A single shared DUI is created lazily.

Supported: local/network entities, models, global entity kinds, sphere/box/poly
zones, labels, onSelect/action, client/server events, exports, commands, groups,
job/gang, item gates and canInteract. Checks run again when confirming.
Interactions are blocked during NUI focus, pause/death, DTlib progress and UI
suspension. Owned registrations are removed when their resource stops.

Compatibility means existing DT.Target option shapes, not global interception
of exports. Scripts calling exports.ox_target or exports['qb-target'] directly
continue using that resource. Neither target resource is replaced or modified.
Bones/offsets and nested target menus are hidden in interact mode for this beta;
use target mode for those options. Raw QB action(entity) signatures must be
adapted to DT.Target onSelect(data). Gameplay authorization stays server-side.

Install into a fresh DTlib folder. Release ZIP contains built UI plus runtime
assets, without node_modules, TSX sources or development tools. GitHub branch
retains editable sources and lockfile. FiveM/DUI live performance, occlusion,
key conflicts and resolution testing remain required before official 1.4.0.
