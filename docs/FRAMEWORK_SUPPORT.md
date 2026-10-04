# DTlib Framework Support

DTlib v1.0.22 aligns the framework adapter with the current public APIs documented by Qbox, ESX Legacy, and ox_core. Framework backends remain optional and are auto-detected.

## Detection

```cfg
DTConfig.Adapters.framework = 'auto' -- settings/sharedConfig.lua
```

Supported values:

```text
auto
qbx / qbox / qbx_core
qb / qb-core
esx / es_extended
ox / oxcore / ox_core
```

Auto-detection order is Qbox -> QB-Core -> ESX -> ox_core.

## Common framework API

```lua
DT.Framework.Name()
DT.Framework.Resource()
DT.Framework.Available(name)
DT.Framework.GetVersion()
DT.Framework.GetJobs()
DT.Framework.GetGangs()
DT.Framework.GetJob(name)
DT.Framework.GetGang(name)
DT.Framework.GetVehicles(filter)
DT.Framework.GetWeapons(filter)
```

Not every framework implements every concept. Unsupported calls return an empty table or `nil` rather than throwing.

## Player API

```lua
DT.Player.Get(source)
DT.Player.GetPlayers()
DT.Player.GetPlayersData()
DT.Player.GetData(source)

DT.Player.GetByCitizenId(citizenid)
DT.Player.GetByUserId(userId)
DT.Player.GetByCharacterId(charId)
DT.Player.GetByIdentifier(identifier)

DT.Player.GetIdentifiers(source)
DT.Player.GetIdentifierByType(source, type)
DT.Player.GetLicenseIdentifier(source)
DT.Player.GetIdentifier(source)
DT.Player.GetCitizenId(source)
DT.Player.GetUserId(source)
DT.Player.GetCharacterId(source)
DT.Player.GetStateId(source)
DT.Player.GetName(source)
DT.Player.GetCoords(source)

DT.Player.GetJob(source)
DT.Player.GetGang(source)
DT.Player.GetGroups(source)
DT.Player.GetGroup(source, filter)
DT.Player.HasGroup(source, filter)
DT.Player.HasPrimaryGroup(source, filter)
DT.Player.SetJob(source, job, grade, onDuty)
DT.Player.SetJobDuty(source, onDuty)
DT.Player.SetGang(source, gang, grade)

DT.Player.GetMoney(source, type)
DT.Player.AddMoney(source, type, amount, reason)
DT.Player.RemoveMoney(source, type, amount, reason)
DT.Player.SetMoney(source, type, amount, reason)

DT.Player.GetMeta(source, key)
DT.Player.SetMeta(source, key, value, replicated)
DT.Player.GetStatus(source, status)
DT.Player.SetStatus(source, status, value)
DT.Player.AddStatus(source, status, value)
DT.Player.RemoveStatus(source, status, value)
DT.Player.HasPermission(source, permission)
DT.Player.Save(source)
```

### Qbox

Uses official `qbx_core` exports for player lookup, jobs/gangs, groups, metadata, money, duty, and job/gang assignment. Qbox permission exports are intentionally not used because current Qbox documentation marks those permission exports deprecated in favor of ACE.

### ESX Legacy

Prefers the modern `ESX.Player(source)` and `ESX.ExtendedPlayers()` interfaces when available, with compatibility fallback to `GetPlayerFromId`. ESX money calls use the account API (`getAccount`, `setAccountMoney`, `addAccountMoney`, `removeAccountMoney`) instead of the legacy cash-only helpers.

DTlib maps its generic `cash` type to ESX account `money`.

### ox_core

Uses `ox_core` exports and `CallPlayer` without making `@ox_core/lib/init.lua` a mandatory DTlib import. This preserves DTlib's optional-backend design.

`DT.Player.GetJob()` and `GetGang()` map to ox_core group types `job` and `gang`. ox_core bank money maps to the character's default account. When `ox_inventory` is running, generic `cash` maps to the `money` inventory item.

ox_core status helpers are exposed through `DT.Player.GetStatus/SetStatus/AddStatus/RemoveStatus`.

### QB-Core

Existing compatibility is retained for legacy DT resources and servers that still run `qb-core`.
