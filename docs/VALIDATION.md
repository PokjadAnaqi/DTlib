# 1.3.0-beta.3 validation

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
