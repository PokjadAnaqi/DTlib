# DTlib 1.3.0-beta.11

This pre-release addresses the DT ecosystem static audit. It changes DTlib only;
consumer resource packages have not been rewritten. All provider source remains
under `modules/`, UI under `html/`, and banner width stays 300px.

## Install

Back up settings, replace the existing `DTlib` resource with the fresh `DTlib/`
folder, then merge your provider settings. Start database/framework/inventory
before DTlib and restart consumers after an upgrade so they load the new init.lua.
No schema migration is needed for this release.

```cfg
add_ace group.god god allow
add_ace group.admin admin allow
ensure DTlib
```

The ACE entries grant permissions to groups. Assign actual player principals to
those groups separately. The hub does not bypass a consumer panel's server checks.

## Inventory catalogue and capabilities

Available on client and server:

```lua
local catalog, err = DT.Inventory.GetCatalog() -- dictionary keyed by item name
if not catalog then return print(err) end
local options = DT.Inventory.GetCatalog({asArray = true}) -- sorted by name
local image = DT.Inventory.GetItemImage('water')
local carrySupported = DT.Inventory.Supports('CanCarryItem')
```

Each catalogue entry preserves provider data and normalizes name, label,
description, weight, image URI and optional rarity. Dictionary, array and wrapped
`items` registries are accepted. This reads item definitions, not player contents.
Image URIs use known provider defaults; custom vendor layouts still need their
own image field. Unknown framework image roots return `image_path_unavailable`.
`Items()` remains available in the provider's raw format; framework fallback
supports QB shared items and ESX's item registry where exposed. QB inventory and
ox_inventory now expose client catalogues as well.

Definition misses are not cached. Successful lookups have a 60-second TTL, are
copied on return, and are invalidated on resource lifecycle/provider changes.
`ClearItemCache(item)` remains available for a runtime definition edit.

`Supports(method)` checks whether the selected adapter exposes the normalized
method (for example `Items`, `GetSlot`, `SetMetadata`, `CanCarryItem`). It is not
a health check or a guarantee that every installed vendor version implements its
documented export. Unsupported methods return `nil, 'unsupported_backend'`.

`CanCarry` no longer converts an unsupported result to true. Handle its three
states: true = capacity accepted; false = denied; nil = unavailable/unsupported.
`AddItem` still delegates to authoritative provider AddItem when the provider has
no capacity preflight. It never treats an explicit capacity denial as permission.
Add/remove/carry quantities must be positive finite integers (nil defaults to 1).

Server usable items can use the existing framework registration through:

```lua
DT.Inventory.RegisterUsableItem('example_item', function(source, item)
    -- Validate use and effects on the server.
end)
```

This uses ESX/QB/QBX framework hooks. ox_inventory item-specific client/server
exports remain configured in its item definitions; this does not replace them.
Callbacks need re-registration if their owning framework or DTlib restarts.

## Restart and admin registration

Consumers loading the new `@DTlib/init.lua` get `DT.IsReady()` and
`DT.AwaitReady(timeoutMs)`. Existing cached function wrappers resolve against a
fresh DT object after DTlib restarts; while stopped they return
`nil, 'dtlib_unavailable'`. Waiting local placement/minigame/UI requests settle
when DTlib stops. Resource-owned UI suspension tokens and menus are cleaned up.
This does not preserve lost gameplay state or automatically recreate targets,
callbacks, shops, waypoints and other registrations. Re-register them after
`DTlib:consumer:ready`, or restart the consumers. Already-running calls through an
old provider can still fail and should not be blindly retried if they mutate data.

Client admin tool registration can now use the restart-aware helper:

```lua
DT.Admin.RegisterTool({
    id = 'zombies', label = 'Zombie Admin',
    description = 'Manage zombie settings and zones', command = 'zombies:admin'
})
```

`DT.Admin.UnregisterTool(id)` forgets the registration. The original
`exports.DTlib:RegisterAdminTool(...)` is still supported but remains a one-shot
registration; repeat it on `DTlib:admin:ready` if using that export directly.
Hub entries are commands; all sensitive actions still require server-side checks.

## Discord and database

Discord has a configurable request timeout (default 10s), protected JSON decoding,
same-member request coalescing, bounded guild/user cache (default 512 entries), and
a cooldown after HTTP 429. It reports `discord_timeout`, `discord_invalid_json`,
`discord_rate_limited` or `discord_busy`; callers may retry later with a bound.
There is no automatic mutation retry. Shared token/guild convars remain unchanged.
Settings: `DTConfig.Discord.timeoutMs`, `cacheSeconds`, `maxCacheEntries`.

```lua
local ready, err = DT.Database.AwaitReady(10000) -- server, inside a coroutine
if not ready then return print(err) end
```

The database helper waits for a driver and probes `SELECT 1`, with a caller timeout
up to 60 seconds. A timeout stops the wait, not an already-submitted driver query.
It is not a migration runner or a transaction spanning money and inventory.

## Native UI and timed banners

Native menus now accept item image, Font Awesome icon/color, metadata and progress,
honour position, readOnly and canClose=false. Programmatic Menu.Close is still
allowed. TextUI renders Font Awesome names instead of displaying their raw strings.
Existing Lation/ox notification routing remains configured normally.

Server example for a banner whose countdown must not restart after queueing:

```lua
DT.NotifyBanner(source, {
    id = 'protection', title = 'SAFE PERIOD',
    description = 'Protection is active.', expiresAt = os.time() + 1800
})
```

`expiresAt` is Unix time in seconds. Server calls include `serverTime` so the
browser calculates a relative deadline; expired queued cards are discarded.
Delivery latency is not measured, and the banner is presentation only: gameplay
expiry must remain server-authoritative. Client calls without serverTime use the
browser wall clock. Existing `duration` calls retain their visible-lifetime behaviour.

## Remaining audit work

- Vehicle Handler's private admin session/save permission mismatch requires a
  consumer patch. DTlib cannot create that resource's local admin session.
- Temperature must stop clearing movement/timecycle effects owned by other
  resources; effect ownership/priority services are not introduced here.
- Quest and other consumers must adopt GetCatalog and restart-aware registration
  to use these additions; a new API does not rewrite their existing fallbacks.
- Class/skill/permit requirements, serial services, shared operation IDs/locks,
  SQL migrations and owned-vehicle creation/rollback remain future additions.

Validation uses Lua/JS simulations and provider-side contract tests, not live
FiveM, multiplayer, SQL driver performance or visual CEF verification.
