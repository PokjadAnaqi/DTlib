# DTlib v1.4.0-beta.4 — P1 bridge overhead

Based on v1.4.0-beta.3. Keep `fx_version 'cerulean'`.

- Cache Qbox client player data from the official `qbx_core:GetPlayerData()` export. Apply player-data, job/gang, load/unload events; invalidate on Qbox restart. A 60-second lazy refresh is a compatibility recovery path.
- Older builds without the client export use a coalesced background callback in DTlib's own coroutine. `DT.Player.GetData()` immediately returns the current snapshot instead of awaiting across an exported function reference. While the first legacy fetch is pending, the snapshot can be empty. Failed legacy hydration is backed off five seconds; late responses cannot overwrite newer data/events or another session.
- Cache progress provider selection; invalidate on config/resolver and client resource start/stop. Query external progress at most once per 200 ms for ordinary `DT.ProgressActive()` reads; `DT.ProgressActive(true)` forces a fresh backend check. DTlib-owned progress remains immediately visible through the active state/event.
- Add callback failure diagnostics containing side, callback name, owner and source. Repeated failures for the same callback are logged at most once per ten seconds; successful callbacks produce no new logs. No callback arguments are logged.

Pair with separately distributed DT_interact v1.0.0-beta.13 to remove per-frame cross-resource progress queries and reduce player-data snapshot reads. DT_interact is not added to this GitHub repository.

## Reported function-reference error

The supplied V8 StackDumpError does not identify the failing API. Moving legacy Qbox hydration into a DTlib-owned coroutine removes one yielding function-reference path; it does not prove that this was the cause of the reported server-side error. Callback errors now have identifying context. If another export/driver is failing, retain the first surrounding error and new callback context for diagnosis.

## Install

Replace the DTlib folder with the fresh runtime folder and merge your settings. Install the paired DT_interact folder, then restart DTlib, DT_interact and consumer resources; reconnect when possible to refresh client code. Keep your existing target mode/adapter settings. Server authorization remains unchanged.

## Validation

21 DTlib Python/Node suites pass (375 Lua files compile; manifest/provider tests retain 220 cases). New tests cover 1000 Qbox reads with one local export/no hot RPC, background single flight/backoff, late response invalidation, logout/character reload/provider restart, progress cache/config/resource invalidation and forced checks, and callback diagnostic throttling. Companion DT_interact has 20 passing Python suites, including 1000 suppression reads resulting in two player-data reads/five progress reads over a simulated one-second clock and forced selection revalidation.

These are mocked correctness/call-count tests. No live FiveM ms benchmark or guarantee that the reported server error is resolved is claimed. UI and raycast P2 behavior are retained.
