# DTlib Server Console Log

DTlib v1.0.3 includes a structured server console logger and runtime status summary.

## Default startup output

On `ensure DTlib`, the server prints the detected framework, inventory, target, database, weather, UI and Discord configuration state. Discord tokens are never printed.

## Console command

```text
dtlib:status
```

Run it from the server console to print the current DTlib runtime status again. In-game use requires the configured admin ACE (`admin` or `god` by default).

## Configuration (`settings/sharedConfig.lua`)

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

The startup/status summary includes `UI`. It reports `lation_ui` when Lation Modern UI is running and selected, otherwise `native`. Start/stop events for `lation_ui` are also logged when resource event logging is enabled.
