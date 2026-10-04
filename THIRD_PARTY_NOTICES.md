# Source notices

DTlib runs as its own resource and does not depend on community_bridge.

The source in integrations/providers and the adapter catalogue/loader derive from TheOrderFivem/community_bridge v0.13.6, commit 8accf38f974067c89e20d1abe816c004ea826dda (https://github.com/TheOrderFivem/community_bridge). Original copyright notices, GPL-3.0 LICENSE and Attributions.md are preserved inside that folder. DTlib's distribution remains GPL-3.0 under the root LICENSE.

Changes include DTlib event and callback transport, resource-local loading, database facade, Cfx syntax normalization, selected-provider guards and dialogue UI routing. This does not claim that imported code was originally written by DTlib.

All upstream modules, lib, locales and web files are present. Upstream root init.lua, fxmanifest.lua and settings are replaced by DTlib's bootstrap, manifest and configuration so a second resource is not started. The runtime file inventory is in docs/IMPORTED_FILES.json.
