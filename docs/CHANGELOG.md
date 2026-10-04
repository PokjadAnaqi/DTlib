# 1.3.0-beta.3

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
