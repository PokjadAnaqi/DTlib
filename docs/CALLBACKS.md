# DTlib Callbacks

DTlib provides client-to-server and server-to-client callback helpers without requiring ox_lib.

## Register a server callback

```lua
DT.Callback.Register('my_resource:getData', function(source, id)
    return { id = id, source = source }
end)
```

## Await from client

```lua
local data = DT.Callback.Await('my_resource:getData', 123)
```

## Async completion callback

```lua
DT.Callback.Trigger('my_resource:getData', function(data)
    print(json.encode(data))
end, 123)
```

## Register a client callback

```lua
DT.Callback.Register('my_resource:getCoords', function()
    return GetEntityCoords(PlayerPedId())
end)
```

## Await a client callback from server

```lua
local coords = DT.Callback.AwaitClient(source, 'my_resource:getCoords')
```

## Unregister

```lua
DT.Callback.Unregister('my_resource:getData')
```

## FiveM function-reference compatibility

Functions returned from or passed across resource exports can be marshalled by Cfx as callable function-reference tables (`__cfx_functionReference`). DTlib normalizes these callables before storing them, so DT ecosystem resources can register callbacks through `@DTlib/init.lua` / `GetObject()` without failing strict Lua `type(...) == 'function'` checks.


## Cross-resource API normalization (v1.0.5)

When `@DTlib/init.lua` imports `GetObject()` from another resource, FiveM/Cfx may represent nested exported functions as callable tables containing `__cfx_functionReference`. DTlib now converts those values to local Lua closures before assigning `DT`. This means capability checks such as `type(DT.Callback.Register) == 'function'` and `type(DT.Callback.Await) == 'function'` work consistently in consumer resources.
