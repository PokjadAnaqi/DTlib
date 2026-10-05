# DTlib 1.3.0-beta.8

DTlib is a standalone FiveM resource with its own provider registry, UI, callbacks and gameplay helpers. It includes modular provider adapters and shared utilities for DT ecosystem scripts.

Lation Modern UI: alert, notify, text UI, progress with steps, input, context menu and list menu. okok integrations: Notify, TextUI, GasStation, Garage, Banking and Phone.

All UI assets live under `html/`; dialogue runtime and editable sources are in `html/dialogue/`. There is no resource-level `web/` folder.

## Install

1. Download the `DTlib.zip` release asset and extract its `DTlib` folder into your resources directory. Replace the existing resource folder with this fresh folder.
2. Start your database, framework, inventory and chosen provider resources first.
3. Add `ensure DTlib` before your DT resources in `server.cfg`.
4. Restart DTlib and its consumers after upgrading. Consumers keep `@DTlib/init.lua` and `dependency 'DTlib'`.

Optional provider resources are installed separately. The default manifest uses `fx_version 'cerulean'`.

- [Settings and examples](docs/ECOSYSTEM.md)
- [Provider matrix](docs/SUPPORT_MATRIX.md)
- [Migration notes](docs/MIGRATION.md)
- [API reference](docs/API.md)
- [Validation and limits](docs/VALIDATION.md)
- [Changelog](docs/CHANGELOG.md)

This is a pre-release. Simulation checks do not replace live FiveM testing with your installed vendor versions. Licensed under GPL-3.0; see [LICENSE](LICENSE).

Full source-pack APIs: `DT.AdapterPack.Get(category, resource)`, `DT.AdapterPack.Call(category, method, ...)`, and `DT.Ecosystem.Utility(name)`. See [full pack integration](docs/ADAPTER_PACK.md) and [source notices](THIRD_PARTY_NOTICES.md).

Provider source now lives directly in `modules/<category>/<provider>`. Utilities are in `lib`, locales in `locales`, and dialogue assets in `web`. The integrations folder has been removed; catalogue and runtime are consolidated.
