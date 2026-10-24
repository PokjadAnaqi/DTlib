# Weather providers

Set `DTConfig.Adapters.weather = 'auto'` in settings/sharedConfig.lua.
Start your weather resource before DTlib. DTlib selects only started resources:
Renewed-Weathersync, then cd_easytime, then qb-weathersync, then native.

The status log, DT.Weather and automatic ecosystem weather selection use the
same runtime choice. Easytime takes precedence over its QB compatibility alias.
Selection is re-evaluated when queried, so stopped providers are not retained.

Each provider has one folder under modules/weather:
- cd_easytime
- qb-weathersync
- renewed-weathersync (resource name: Renewed-Weathersync)
- native (fallback)

client.lua and server.lua register DTlib adapters. compat.lua preserves the
legacy ToggleSync/GetResourceName API in the same provider folder.
The manifest and bundled source catalog use these consolidated paths.
Short configuration aliases qb, renewed and easytime remain supported.

Install into a fresh DTlib folder to remove obsolete qb, renewed and _default
directories. Existing release ZIPs are unchanged until a new release is published.
Check the active provider using dtlib:status from the server console.
