# 1.3.0-beta.6 validation

Install lupa and run `python tests/test_contracts.py` and `python tests/test_adapter_pack.py`.

- All 367 Lua files compile under the Lua 5.4 test compiler (Cfx hash literals normalized for compilation).
- 81 client and 47 server/shared manifest scripts load with Cfx stubs.
- 219 normalized registry provider/side combinations initialize.
- A separate 219 complete source-pack provider/side combinations initialize in isolated runtimes.
- All 22 named utilities load on their permitted runtime sides; path guards and actual missing-method delegation pass.
- Every one of the 305 upstream module, library, locale and web files has a corresponding local path, verified against IMPORTED_FILES.json.
- Lation and okok contract tests, inventory argument order, native skill progression, shop session/stock/refund behavior and native menu cancellation/nested opening pass.

These are static and simulated checks, not live vendor/FiveM execution. Purchased vendor versions, legacy database schemas, clothing persistence, dispatch delivery, shell spawning and in-game UI still require target-server testing. File inclusion and initialization do not prove every gameplay path works with every vendor release.

Layout checks assert that integrations and the separate pack catalogue/runtime files are absent. All 226 imported provider module files are directly under modules.

Run `python tests/test_database.py` for database export arguments, live resource state changes and actionable missing-driver diagnostics.

## beta.4 full audit

Run `python tests/test_lifecycle.py` and `node tests/test_gizmo.js` in addition to the existing contract, adapter-pack and database suites. Regression checks cover native placement confirm/cancel, initial freeze state, PED changes, freezePlayer=false, Lua/JS freeze ownership, Cfx export self/arguments, toggle-only visibility retries, nested suspension, callback nil values/timeouts/source validation/resource stop/player disconnect, mixed-case provider selection and native TextUI fallback.

The current GitHub placement recovery changes were preserved. JavaScript runtime/UI files pass Node syntax checks. These checks use mocked native/export calls; they do not establish compatibility with every live paid-provider version or replace client/server gameplay tests. No server was accessed or restarted during this audit.

## beta.5 UI layout

Dialogue files are relocated intact to html/dialogue. The root NUI iframe resolves dialogue/dist/index.html; its compiled JS/CSS URLs remain relative to that page. The manifest packages html/**. The imported-file inventory maps historical upstream paths to the new local paths. Full contract/provider/database/lifecycle regressions pass; live FiveM NUI testing remains required.

- cd_easytime DT.Weather adapter manifest registration and auto-resolution path checked.

## Verified beta.6 regression run

369 Lua files compile; 82 client and 48 server/shared manifest scripts load. Both sets of 219 provider/side cases pass. Behavioral Easytime tests cover automatic selection ahead of qb aliases, GetAllData/GetWeather fallback, normalized weather/time, explicit aliases and copied data snapshots. Database and beta.4 lifecycle regressions pass. Python bytecode/cache files are excluded from repository and installation ZIP. Live FiveM/vendor testing remains required.

## beta.7 banner checks

Client/server banner API routing and native provider isolation pass. Renderer tests verify bounded queue, expiry, ID replacement, duplicate stacking, escaped text, image fallback, countdown and removal/clear timer cleanup. Existing Lua/provider/Easytime/lifecycle checks pass. Real FiveM NUI and installed Font Awesome CDN/image availability still require in-game validation.

## beta.11 regression checks

Run the existing Python/Node suites plus `python tests/test_hardening.py` and
`node tests/test_native_ui.js`. The additions cover inventory miss recovery,
copied definitions, cache expiry/provider stop, normalized catalogues, invalid
counts and capability errors; Discord timeout/late response/invalid JSON,
guild cache isolation, 429 cooldown and concurrent request coalescing; owner UI
cleanup; stable consumer wrappers across restart; database readiness/failure/
timeout; native UI detail handling; and absolute banner/queued expiry.

These are simulations. No live FiveM, CEF visual, vendor backend or multiplayer
performance test is claimed. After installation, check the item selector against
your actual inventory, admin open/save permissions, restart recovery, provider
readiness and expired protection banners on a test server.
