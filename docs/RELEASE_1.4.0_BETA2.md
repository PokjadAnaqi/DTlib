# DTlib v1.4.0-beta.2

This prerelease updates the DT.Target bridge for standalone DT_interact and fixes runtime version/status reporting. DT_interact is distributed separately; no DT_interact engine, source or asset is published in this repository/release.

Download DTlib.zip for the compiled runtime. Replace the DTlib folder with the fresh folder, merge your settings, start your target backend first, then restart DTlib and all consumers.

For DT_interact users:

```lua
DTConfig.Interaction.mode = 'target'
DTConfig.Adapters.target = 'DT_interact'
```

Otherwise keep your existing target backend or target = 'auto'. The former embedded mode = 'interact' is a migration alias for the external DT_interact provider and requires that separate resource to be installed.

Editable native UI TSX is on release/1.4.0-beta.2. The runtime ZIP excludes new TSX source, node_modules and development tooling.

Validation: 375 Lua syntax checks, manifest validation, 220 provider/side cases, runtime version/status/target-adapter checks and existing regression suites. Real FXServer target compatibility and UI input still need deployment testing.
