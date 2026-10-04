# DTlib 1.3.0-beta.1

DTlib is an independent FiveM runtime library with its own provider registry, adapters, UI, callbacks and gameplay helpers.

Lation Modern UI: alert, notify, text UI, progress with steps, input, context menu and list menu. okok integrations: Notify, TextUI, GasStation, Garage, Banking and Phone.

## Install

1. Replace the existing resource folder with this source folder, named `DTlib`.
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
