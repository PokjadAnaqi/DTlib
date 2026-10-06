from lupa.lua54 import LuaRuntime
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for allowed in (False, True):
 lua=LuaRuntime(unpack_returned_tuples=True)
 lua.execute('events={};calls={};DT={Security={}};function RegisterNetEvent(n,f) events[n]=f end;function TriggerClientEvent(...) calls[#calls+1]={...} end;function source() end')
 lua.globals().DT.Security.RequireAdmin=lambda src: allowed
 lua.globals().DT.Security.RateLimit=lambda *args: True
 lua.execute((root/'lib/admin/server.lua').read_text())
 lua.globals().source=42
 lua.execute("events['DTlib:server:adminOpen']()")
 assert lua.eval('#calls')==(1 if allowed else 0)
 if allowed: assert lua.eval('calls[1][1]')=='DTlib:client:adminOpen' and lua.eval('calls[1][2]')==42
print('Admin hub: server authorization gate PASS')
