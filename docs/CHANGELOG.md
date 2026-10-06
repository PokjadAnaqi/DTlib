# 1.3.0-beta.9

- Add `/dtlib:admin` registry hub for ecosystem admin panel commands.
- Gate hub access through server-side DT.Security.RequireAdmin and rate limit requests.
- Keep panel-specific authorization in each consumer resource.

# 1.3.0-beta.7

- Add native Delta banner notifications with image/Font Awesome icon, subtitle, readable message and lifetime bar.
- Add DT.NotifyBanner on client/server; force only banner calls to native UI while retaining configured notify providers.
- Add positioned queues, bounded visible cards, duplicate stacking and ID replacement.
- Clear timers/queues during UI suspension; retain beta.6 weather fix.

# 1.3.0-beta.6

- Fixed the advertised `cd_easytime` weather provider: the source pack existed but was not registered or loaded by the DT.Weather runtime.
- Added first-class client/server `cd_easytime` DT.Weather adapters using Easytime `GetAllData()` / `GetWeather()` exports.
- Auto weather resolution now checks the real `cd_easytime` resource before `qb-weathersync`, avoiding false selection through Easytime's `provide` aliases.
- Added `DT.Weather.GetData()` for provider-specific weather/time snapshots while keeping `GetCurrent()` and `GetTime()` provider-neutral.
- No consumer-side weather provider setting is required; `DTConfig.Adapters.weather = 'auto'` is sufficient.

# 1.3.0-beta.5

- Consolidate all DTlib UI assets under html; move dialogue runtime and editable sources to html/dialogue.
- Remove the resource-level web folder, update the dialogue iframe, manifest and imported-file inventory.
- Keep provider APIs, native UI and beta.4 lifecycle fixes unchanged.
- Upgrade with a fresh DTlib folder so obsolete web files are removed.

# 1.3.0-beta.4

- Full regression audit against GitHub main, preserving the latest placement recovery changes.
- Fix Cfx overlay export argument forwarding and prevent delayed retries from replaying toggle-only visibility APIs.
- Make Lua the sole owner of native placement PED freezing; preserve tracked PED states and honour freezePlayer=false.
- Resolve explicitly configured provider names without case-sensitive mismatches.
- Add 30-second callback timeout, resource/disconnect cleanup, and preserve nil arguments/results.
- Fall back to native TextUI when a provider explicitly returns false.

- Fix native Prop Placement cleanup so ESC/confirm cannot leave the player PED frozen.
- Restore PED freeze state in both the Lua placement controller and native gizmo runtime.
- Preserve and restore the previous DTlib TextUI after placement help closes.
- Reassert DT_temperature visibility after placement camera teardown so the temperature widget returns reliably.
- Keep cancel/confirm transform semantics unchanged.

# 1.3.0-beta.3

- Report database driver states in missing-backend errors and expose DT.Database.Status().
- Align DT.Version with the manifest release version.

- Move all 226 imported module files directly into modules and utilities/locales/web assets to resource-level folders.
- Remove integrations; combine source catalogue and loader into the existing ecosystem modules.
- Preserve normalized DT adapters with dt_client.lua/dt_server.lua where filenames overlap.
- Use explicit startup script entries so optional provider sources load only after selection.

# 1.3.0-beta.2

- Bundle every runtime provider module, library, locale and dialogue asset from the complete 22-category/153-profile source pack.
- Add DT.AdapterPack for full provider signatures, DT.Ecosystem missing-method delegation and utility loading.
- Keep DTlib bootstrap, normalized contracts, Lation/okok implementations and native helpers.
- Preserve GPL LICENSE and original attribution; no external community_bridge resource required.

# Changelog

## 1.3.0-beta.1

- Replaced the imported provider runtime with DTlib's own local factory registry and direct export/event adapters.
- Retained 22 categories and 153 provider profiles. Runtime capability discovery now lists actual callable methods by side.
- Removed the bundled provider source tree and dialogue iframe.
- Added DTlib-native dialogue menus, server shop checkout, memory-based native skills and DT utility modules.
- Retained Lation alert, notify, text UI, step progress, input, context menu and list menu; retained okok adapters and native DT placement/waypoint.
- Explicit provider selection reports unavailable resources. Unsupported/no-op operations are no longer presented as implemented.
- Added source, manifest, provider initialization and behavioral contract tests.

This version changes the legacy helper loader and native skill persistence. See [MIGRATION.md](MIGRATION.md). Older release history remains in the repository tags.
