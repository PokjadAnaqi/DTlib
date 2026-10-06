# DTlib FiveM / Cfx Support

DTlib v1.0.22 adds small wrappers around commonly repeated FiveM primitives. These helpers do not replace natives; they provide a consistent DT namespace and reduce duplicated glue across DT resources.

## State bags

Server:

```lua
DT.State.GetPlayer(source, key)
DT.State.SetPlayer(source, key, value, replicated)
DT.State.GetEntity(entity, key)
DT.State.SetEntity(entity, key, value, replicated)
DT.State.GetGlobal(key)
DT.State.SetGlobal(key, value)
DT.State.OnChange(keyFilter, bagFilter, callback)
DT.State.RemoveHandler(cookie)
```

Client:

```lua
DT.State.GetLocal(key)
DT.State.SetLocal(key, value, replicated)
DT.State.GetPlayer(serverId, key)
DT.State.GetEntity(entity, key)
DT.State.SetEntity(entity, key, value, replicated)
DT.State.GetGlobal(key)
DT.State.OnChange(keyFilter, bagFilter, callback)
DT.State.RemoveHandler(cookie)
```

DTlib follows Cfx state-bag semantics: server-set values replicate by default; client-set values are local by default unless replication is explicitly requested. Prefer granular keys rather than mutating nested tables in-place.

## Routing buckets

Server only:

```lua
DT.Routing.GetPlayer(source)
DT.Routing.SetPlayer(source, bucket)
DT.Routing.GetEntity(entity)
DT.Routing.SetEntity(entity, bucket)
DT.Routing.SetLockdown(bucket, 'strict')
DT.Routing.SetPopulation(bucket, false)
```

Valid lockdown modes accepted by DTlib are `strict`, `relaxed`, `inactive`, and `full`.

## Entity/network helpers

```lua
DT.Entity.Exists(entity)
DT.Entity.GetNetworkId(entity)
DT.Entity.FromNetworkId(netId)
DT.Entity.Delete(entity)
```

Client additionally provides:

```lua
DT.Entity.RequestControl(entity, timeoutMs)
```

## OneSync

```lua
DT.OneSync.Enabled()
DT.OneSync.Mode()
```

Server also provides a server-setter vehicle helper:

```lua
local vehicle = DT.OneSync.CreateVehicle(
    `blista`,
    'automobile',
    vec3(100.0, 100.0, 30.0),
    90.0
)
```

## ACE

Server only:

```lua
DT.Ace.Allowed(source, 'admin')
DT.Ace.Has(source, 'admin')
```

ACE permission checks should remain server-authoritative.

## Player identifiers

```lua
local ids = DT.Player.GetIdentifiers(source)
local license = DT.Player.GetLicenseIdentifier(source) -- license2 preferred, license fallback
local fivem = DT.Player.GetIdentifierByType(source, 'fivem')
```

`GetIdentifiers` returns a map keyed by identifier type rather than requiring every DT resource to parse the `type:value` strings itself. `GetLicenseIdentifier` prefers `license2` when available, following current Cfx guidance, and falls back to `license`.
