> v1.4.0-beta.3: reduce idle resmon overhead with an on-demand gizmo tick and idle waypoint/zone guards. See docs/RELEASE_1.4.0_BETA3.md.

> v1.4.0-beta.2: interaction UI/input is now owned by the separately distributed DT_interact resource. DTlib keeps its DT.Target bridge and existing optional target adapters. See docs/STANDALONE_INTERACT.md. Runtime version and boot target reporting are aligned with the installed manifest/provider.

# DTlib 1.4.0-beta.1

Beta: React native panels and optional E/DUI interactions. See [beta setup and limitations](docs/BETA140.md).

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
- [Central update log and consumer list](docs/UPDATE_CHECK.md)
- [beta.11 ecosystem migration and API additions](docs/BETA11.md)

Simulation checks do not replace live FiveM testing with your installed vendor versions. Licensed under GPL-3.0; see [LICENSE](LICENSE).

Discord profile/avatar lookup only requires the shared server convar
`dt_eco_discord_bot_token` and the player's Discord identifier. Guild ID is
optional for profiles and required only for roles/guild membership checks.

Full source-pack APIs: `DT.AdapterPack.Get(category, resource)`, `DT.AdapterPack.Call(category, method, ...)`, and `DT.Ecosystem.Utility(name)`. See [full pack integration](docs/ADAPTER_PACK.md) and [source notices](THIRD_PARTY_NOTICES.md).

Provider source lives directly in `modules/<category>/<provider>`. Utilities are in `lib`, locales in `locales`, and dialogue assets in `html/dialogue`. Catalogue and runtime are consolidated.


## Central admin hub — beta.9

Open `/dtlib:admin` to see registered ecosystem admin panels. The server checks `DT.Security.RequireAdmin` before opening the hub. Each consumer resource must register its existing panel command with DTlib; see `docs/API.md`. Its own panel must keep its normal server-side permission checks.
