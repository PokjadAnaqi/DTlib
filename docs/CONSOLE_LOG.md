# DTlib Server Console Log

DTlib v1.0.3 includes a structured server console logger and runtime status summary.

## Default startup output

On `ensure DTlib`, the server prints one line with the version and primary adapters. The client prints one line with its version and target adapter. A missing database still reports an error. Module readiness and backend lifecycle details use debug logging.

The central update check includes the number of resources using DTlib. Enable `DTConfig.Debug` to see their names. `GetDTlibConsumers` returns the full list.

## Console command

```text
dtlib:status
```

Run it from the server console to print the current DTlib runtime status in two lines. In-game use requires the configured admin permission.

## Configuration (`config/shared.lua`)

```cfg
DTConfig.Console = {
    enabled = true,
    startupSummary = true,
    resourceEvents = true,
    timestamps = true,
    audit = true
}
DTConfig.Debug = false
```


## API

```lua
DT.Logger.Info('MODULE', 'Module ready')
DT.Logger.Warn('MODULE', 'Optional backend missing')
DT.Logger.Error('MODULE', 'Operation failed', { error = err })
DT.Logger.Audit('ADMIN', 'Configuration changed', { source = source })
DT.Logger.Debug('MODULE', 'Debug detail')

local status = DT.Logger.GetRuntimeStatus()
DT.Logger.PrintStatus('manual check')
```

Server exports are also available:

```lua
local status = exports.DTlib:GetRuntimeStatus()
exports.DTlib:PrintStatus('my-resource')
```

## UI backend

The status summary includes the selected UI adapter. Backend start and stop messages are shown when both `resourceEvents` and `DTConfig.Debug` are enabled.
