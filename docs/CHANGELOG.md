# Unreleased

- Consolidate weather adapters and legacy compatibility APIs into one folder per provider.
- Make automatic ecosystem weather selection and runtime status use DT.Weather.Name(), including Easytime before QB compatibility aliases.
- Refresh source paths and preserve short provider aliases.

# 1.3.1

- Add a central DTlib official-release checker at server start and every 60 minutes by default.
- Print one DTlib update notice and a sorted list of active resources using DTlib; never print per-consumer dependency-outdated warnings.
- Detect consumers from dependency metadata or @DTlib script imports. Suppress duplicate messages for the same installed/latest pair; bound requests with timeout and use ETag caching.
- Add UpdateCheck settings, CheckForUpdates and GetDTlibConsumers exports, with semantic version comparison including beta-to-official ordering.

# 1.3.0 — official

- Promote the 1.3.0 beta line to the official release, including the Discord token-only profile/avatar hotfix below.
- Align resource metadata and `DT.Version` with `1.3.0`; publish as a normal release rather than a pre-release.
- Retain the full provider registry, Lation/okok integrations, native UI, callbacks, gameplay helpers, inventory hardening and restart recovery from beta.11.
- Keep HTML-only UI assets, 300px banners, `admin`/`god` ACE defaults and the shared Discord token convar.
- Package the resource as `DTlib.zip` with one `DTlib/` root. Simulation validation is documented; live vendor/FiveM testing remains deployment-specific.

# beta.11 Discord profile hotfix

- Fetch global user profiles and avatars through `/users/{id}` using the shared bot token, without requiring a Guild ID.
- Add `DT.Discord.GetUser` and keep the `GetMember().user` profile shape when the Guild ID is omitted, marked `profileOnly = true` with no roles.
- Keep role checks fail-closed without a Guild ID; retain timeout, request coalescing, cache limits and rate-limit handling.
- Do not modify the published beta.11 tag; this hotfix is delivered from main and the updated installation ZIP.

# 1.3.0-beta.11

- Keep native banners at 300px; support absolute `expiresAt` and discard expired queued cards.
- Fix inventory misses and stale definition caches across provider changes and resource lifecycle events; copy cached definitions before returning them.
- Add normalized inventory catalogue/image APIs, per-method capability checks, usable-item facade and positive finite integer validation for add/remove/carry counts.
- Expose QB/ESX framework catalogue fallback and client-side item definitions; fix unknown item lookup returning the complete registry.
- Add Discord request timeout, protected decoding, duplicate request coalescing, bounded guild/user cache and rate-limit cooldown handling.
- Release UI suspension tokens when their owner stops; clean up registered admin tools and native menus on owner stop.
- Rebind consumer function wrappers after DTlib restart, expose readiness, settle waiting placement/minigame requests and provide restart-aware admin registration.
- Add database connection-ready probe with caller timeout.
- Improve native menu image/icon/metadata/progress support, positioning and read-only/canClose handling; render Font Awesome TextUI icons.
- Correct admin ACE and HTML asset documentation. Consumer-specific fixes and additional proposed gameplay services remain separate work; see BETA11.md.

# 1.3.0-beta.10

- Accept ACE objects `admin` and `god` by default for DTlib admin tools.
- Document group assignments using the requested server.cfg ACE rules.
- Test both accepted permissions and denied access.

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

