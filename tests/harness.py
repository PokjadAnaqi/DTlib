from pathlib import Path
from lupa.lua54 import LuaRuntime
import json,re
root=Path(__file__).resolve().parents[1]
def runtime(server=False,resources=()):
 l=LuaRuntime(unpack_returned_tuples=True)
 g=l.globals();g.pyread=lambda resource,path: (root/path).read_text() if resource=='DTlib' and (root/path).is_file() else ('lib=lib or {};cache={};return lib' if resource=='ox_lib' and path=='init.lua' else 'return {}' if resource=='PolyZone' else None)
 l.execute('''states={};handlers={};threads={};calls={};GlobalState={};LocalPlayer={state={}};cache={ped=1};
 function GetCurrentResourceName() return 'DTlib' end
 function GetInvokingResource() return 'consumer' end
 function GetResourceState(name) return states[name] or 'missing' end
 function LoadResourceFile(resource,path) return pyread(resource,path) end
 function GetResourceMetadata(...) return '1.2.0' end
 function GetGameTimer() return 1000 end
 function GetConvar(_,default) return default end
 function AddEventHandler(name,cb) handlers[name]=cb end
 function RegisterNetEvent(name,cb) if cb then handlers[name]=cb end end
 function RegisterNUICallback(name,cb) handlers[name]=cb end
 RegisterNuiCallback=RegisterNUICallback
 function AddStateBagChangeHandler(...) end
 function CreateThread(fn) threads[#threads+1]=fn end
 function Wait(...) end
 function SetTimeout(...) end
 function TriggerEvent(...) end
 function TriggerClientEvent(...) end
 function TriggerServerEvent(...) end
 function SendNUIMessage(...) end
 function SetNuiFocus(...) end
 function PlayerId() return 1 end
 function GetPlayerServerId() return 10 end
 function DoesEntityExist() return true end
 function GetVehicleNumberPlateText() return 'TEST123' end
 function GetPlayers() return {} end
 function GetPlayerPed() return 1 end
 function GetPlayerIdentifiers() return {} end
 function GetPlayerName() return 'Tester' end
 function GetVehicleFuelLevel() return 55.0 end
 function SetVehicleFuelLevel(...) end
 function vec3(x,y,z) return {x=x,y=y,z=z} end
 vector3=vec3
 function joaat(s) return 42 end
 function IsPlayerAceAllowed() return true end
 function NetworkIsSessionStarted() return false end
 function GetEntityCoords() return vec3(0,0,0) end
 function GetEntityModel() return 42 end
 function GetVehicleClass() return 1 end
 function warn(...) end
 table.clone=function(t) local o={};for k,v in pairs(t) do o[k]=v end;return o end
 promise={new=function() return {resolve=function() end} end};Citizen={Await=function() return {} end}
 json={decode=function() return {} end,encode=function() return '{}' end}
 local empty={Shared={Items={},Jobs={}},Functions={GetPlayerData=function() return {items={},charinfo={},metadata={},job={name='test',grade={level=0}}} end,GetQBPlayers=function() return {} end},PlayerData={charinfo={},metadata={},job={name='test',grade={level=0}}}}
 exports=setmetatable({}, {__call=function() end,__index=function(_,name)
  return setmetatable({}, {__index=function(_,method) return function(...)
   calls[#calls+1]={resource=name,method=method,args={...}}
   if method=='GetCoreObject' or method=='getSharedObject' then return empty end
   if method=='GetPlayerData' then return empty.Functions.GetPlayerData() end
   if method=='GetJobs' or method=='getJobs' then return {} end
   if method=='isOpen' then return false end
   return {} end end}) end})
 DT={Callback={Register=function() end,Await=function() end,AwaitClient=function() end},Database={}};DTConfig={Adapters={ui='auto',notify='auto',inventory='auto',target='auto'},UI={menuPosition='offcenter-right'},Ecosystem={enabled=true,providers={}},Debug=false}
 ''')
 g.IsDuplicityVersion=lambda:server
 for resource in resources:g.states[resource]='started'
 for file in ['shared/utils.lua','shared/core.lua','lib/modules/shared.lua','modules/ecosystem/catalog.lua','modules/ecosystem/runtime.lua']:
  l.execute((root/file).read_text())
 return l

def load_manifest(server=False, resources=()):
 l=runtime(server,resources)
 l.execute('function RegisterCommand(...) end;function RegisterKeyMapping(...) end;function AddTextEntry(...) end;function GetHashKey(v) return 42 end;function IsHudHidden() return false end;function IsRadarHidden() return false end;function GetNetworkTimeAccurate() return 0 end;function GetCloudTimeAsInt() return 100000 end;function GetConvarInt(_,v) return v end')
 manifest=(root/'fxmanifest.lua').read_text()
 paths=[]
 for block in ['shared_scripts',('server' if server else 'client')+'_scripts']:
  content=re.search(block+r'\s*\{(.*?)\}',manifest,re.S)[1]
  for pattern in re.findall(r"'([^']+)'",content):
   if pattern.startswith('@') or pattern.endswith('.js'):continue
   matches=sorted(root.glob(pattern));assert matches,pattern
   paths+=matches
 for p in paths:
  source=re.sub(r'`([^`]+)`',lambda m:'joaat('+repr(m[1])+')',p.read_text())
  try:l.execute(source)
  except Exception as error:raise AssertionError(f'{p.relative_to(root)}: {error}')
 return l,len(paths)
