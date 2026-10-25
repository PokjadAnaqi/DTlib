# beta.3 runtime version/status correction

The earlier companion bundle changed fxmanifest.lua to 1.4.0-beta.2 but left shared/core.lua hardcoded to 1.4.0-beta.1. That made boot logs, DT.GetVersion(), GetVersion exports and update checks report the old version.

DT.Version now reads GetResourceMetadata(GetCurrentResourceName(), 'version', 0), keeping runtime reporting aligned with the manifest. Server status auto-detection also prioritizes DT_interact and watches its resource lifecycle instead of reporting the ox_target compatibility alias first.

Changed runtime files: shared/core.lua and lib/logger/server.lua. The resource version remains 1.4.0-beta.2. Replace these two files (with the beta.3 manifest already installed) or install this corrected complete bundle, then restart DTlib and its consumer resources. DT_interact has its separate 1.0.0-beta.1 version.

Validation: runtime metadata/status regression passed; 375 Lua files compiled; 220 provider/side cases and the update-checker suite passed.
