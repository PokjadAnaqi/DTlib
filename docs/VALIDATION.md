# 1.3.0-beta.5 validation

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
