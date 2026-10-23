# DTlib Configuration Policy

DTlib v1.2.0 does not use `dtlib_*` convars. Runtime selection and behaviour are configured in resource files.

## Shared settings

Edit `settings/sharedConfig.lua` for framework, inventory, target, database, weather, UI, notify, console logging, placement, waypoint, minigames, security, debug and strict-mode settings.

## Client/server settings

Use `settings/clientConfig.lua` and `settings/serverConfig.lua` for settings that should only exist on one runtime side.

## Discord

Discord credentials stay outside the resource. Profiles and global avatars only
require this shared server convar (use `set`, not replicated `setr`):

```cfg
set dt_eco_discord_bot_token "YOUR_TOKEN"
# Optional, for roles/guild membership only:
# set dt_eco_discord_guild_id "YOUR_GUILD_ID"
```

Never store the bot token inside the DTlib resource.
Players still need a `discord:` identifier. Missing identifiers, inaccessible
users, invalid tokens and API errors are reported to callers; they are not fixed
by removing the Guild ID requirement. Keep an avatar placeholder on failure.

## v1.2.0 ecosystem expansion

See [ECOSYSTEM.md](ECOSYSTEM.md) for Lation Alert/List Menu, per-module UI settings,
okok providers, DTlib adapters and installation details.
See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) for all provider categories.
