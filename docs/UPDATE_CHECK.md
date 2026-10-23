# DTlib update log

DTlib checks its official GitHub latest release five seconds after startup and
every 60 minutes by default. A new release is detected on the next successful
check, not pushed directly into the server. No token is required.

```text
[DTlib:UPDATE] UPDATE AVAILABLE | Installed: 1.3.1 | Latest: v1.3.2
[DTlib:UPDATE] Download: https://github.com/PokjadAnaqi/DTlib/releases/latest
[DTlib:UPDATE] Scripts using DTlib (2):
[DTlib:UPDATE]   - DT_gather
[DTlib:UPDATE]   - DT_questsystem
```

Only DTlib gets an update warning. Other resources are listed by name, without
their versions or individual dependency warnings. The same installed/latest
pair is printed once per DTlib runtime; restarting DTlib prints it again.
An up-to-date startup also prints its status/list by default. Network/JSON/API
errors leave gameplay running and are retried on the next polling interval.

Settings are in `DTConfig.UpdateCheck`: enabled, intervalMinutes (5–1440),
logUpToDate, listConsumers, includeStopped. By default, the list contains started
or starting resources declaring `dependency 'DTlib'` or an `@DTlib/` script
import. Resources only calling exports without either metadata declaration
cannot be discovered by this method. The list refreshes when a status is printed.

Server exports: `exports.DTlib:CheckForUpdates()` requests a check (unless disabled
or already checking); `exports.DTlib:GetDTlibConsumers()` returns sorted
`{name, version, state}` entries. Neither downloads or restarts resources.
No consumer code changes are needed for resources with the metadata above.
