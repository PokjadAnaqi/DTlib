# Source notices

DTlib runs as its own resource and does not depend on community_bridge.

Provider source modules under modules, imported utilities under lib, locales and web assets derive from TheOrderFivem/community_bridge v0.13.6, commit 8accf38f974067c89e20d1abe816c004ea826dda (https://github.com/TheOrderFivem/community_bridge). Original copyright notices are preserved. GPL-3.0 LICENSE and ATTRIBUTIONS.md are at the resource root. DTlib does not claim original authorship of imported code.

Changes include DTlib events and callback transport, local source loading, a database facade, Cfx syntax normalization, provider selection guards, dialogue routing and Shell utility return values. Exact paths are in docs/IMPORTED_FILES.json and docs/ADAPTER_SOURCES.json. Existing normalized DT adapters with conflicting filenames use dt_client.lua or dt_server.lua in their provider folders.

All upstream modules, lib, locales and web files are present. Upstream root bootstrap, manifest and settings are replaced by DTlib's own files. There is no integrations folder; provider metadata and source loading share the existing ecosystem catalogue and runtime modules.

## Font Awesome Free 6.7.2

The compiled UI bundles Font Awesome Free CSS and fonts. Icons: CC BY 4.0; fonts: SIL OFL 1.1; code: MIT. See `docs/FONT_AWESOME_LICENSE.txt`.
