# DTlib v1.4.0-beta.2 — standalone interaction migration

DT_interact v1.0.0-beta.1 now owns the interaction engine, UI/TSX, icons, geometry, callbacks, input, compatibility exports and ped helpers. DTlib no longer contains/runs its embedded Interact engine or mounts an interaction UI.

DTlib remains the integration bridge. Existing DT.Target calls retain their names and data contract, including custom option fields and the original registering owner across DTlib's nested export hop. The legacy ecosystem Target source-pack API is also routed to DT_interact. Optional historical ox/qb/sleepless bridge adapters remain available for older deployments; they do not run a target engine or become dependencies of the new setup.

Use:

```lua
DTConfig.Interaction.mode = 'target'
DTConfig.Adapters.target = 'DT_interact'
```

Auto detection prioritizes DT_interact. The old `mode = 'interact'` setting aliases to the standalone provider for migration; it does not restore an embedded engine. Move all E/cursor/geometry/visual settings into `DT_interact/config.lua`.

Start order is framework, DT_interact, DTlib, inventory and gameplay consumers. DT_interact has no DTlib dependency, so there is no circular dependency. Restart all consumers after changing the provider.

DTlib menu/input opening releases interaction focus before taking its own NUI focus. Progress emits DTlib:progress:state; existing UI suspension/resume events also suppress the independent layer. These events are optional integrations, not a dependency for standalone DT_interact.

DT_interact is a separately distributed optional resource. Its engine, source and ZIP are not included in the DTlib GitHub repository or prerelease. Existing ox_target/qb-target/sleepless adapters remain available when that external resource is not installed.
