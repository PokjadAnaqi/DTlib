from lupa.lua54 import LuaRuntime
from pathlib import Path
from harness import load_manifest
root=Path(__file__).resolve().parents[1]
for permissions, legacy_god, expected in [
    ({"admin", "mod", "support"}, False, True),
    ({"mod", "support"}, False, False),
    ({"support"}, False, False),
    ({"god"}, False, False),
    ({"god"}, "god", True),
    ({}, False, False),
]:
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute("allowed={}; function IsPlayerAceAllowed(source,ace) return allowed[ace] or false end; DTConfig={Security={adminAce='admin',godAce='god'}}; DT={Security={}}; function TriggerClientEvent(...) end; function AddEventHandler(...) end")
    for permission in permissions: lua.globals().allowed[permission]=True
    lua.globals().DTConfig.Security.godAce = legacy_god
    lua.execute((root/'lib/security/server.lua').read_text())
    assert lua.eval('DT.Security.IsAdmin(42)') is expected
    assert lua.eval("DT.Security.IsAdmin(42, 'god')") is ('god' in permissions)

for allowed in (False, True):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute('events={};calls={};DT={Security={}};function RegisterNetEvent(n,f) events[n]=f end;function TriggerClientEvent(...) calls[#calls+1]={...} end')
    lua.globals().DT.Security.RequireAdmin=lambda src: allowed
    lua.globals().DT.Security.RateLimit=lambda *args: True
    lua.execute((root/'lib/admin/server.lua').read_text())
    lua.globals().source=42
    lua.execute("events['DTlib:server:adminOpen']()")
    assert lua.eval('#calls')==(1 if allowed else 0)
    if allowed: assert lua.eval('calls[1][1]')=='DTlib:client:adminOpen' and lua.eval('calls[1][2]')==42
for provider, groups in [
    ('qbx_core', [('admin', True), ('mod', False)]),
    ('qb-core', [('admin', True), ('mod', False)]),
    ('es_extended', [('admin', True), ('superadmin', True), ('mod', False), ('user', False)]),
]:
    lua, _ = load_manifest(True, [provider])
    lua.execute('''
        exports['qb-core'] = {GetCoreObject = function()
            return {Functions = {HasPermission = function(_, permission) return group == permission end}}
        end}
        exports.es_extended = {getSharedObject = function()
            return {GetPlayerFromId = function()
                return {getGroup = function() return group end}
            end}
        end}
        function IsPlayerAceAllowed(_, ace) return framework == 'qbx_core' and group == ace end
    ''')
    lua.globals().framework = provider
    for group, expected in groups:
        lua.globals().group = group
        assert lua.eval('DT.Security.IsAdmin(42)') is expected
        assert lua.eval("DT.Security.IsAdmin(42, 'custom.admin')") is False
    lua.execute("DTConfig.Security.frameworkAdmin = false; group = 'admin'")
    assert lua.eval('DT.Security.IsAdmin(42)') is (provider == 'qbx_core')

print('Qbox, QB-Core and ESX admin roles, explicit ACE and admin hub gate PASS')
