from harness import runtime, root

lua=runtime()
lua.execute('''
 DT.Modules.Register('weather','Renewed-Weathersync',{resource='Renewed-Weathersync',available=function() return true end})
 DT.Modules.Register('weather','qb-weathersync',{resource='qb-weathersync',available=function() return true end})
 assert(DT.Modules.Resolve('weather','RENEWED-WEATHERSYNC',{'qb-weathersync'},{},'none').name=='Renewed-Weathersync')
''')
print('Explicit mixed-case provider selection PASS')
for side in ['client','server']:
 lua=runtime(side=='server')
 lua.execute('''
 timeouts={};responses={};CreateThread=function(fn) fn() end
 SetTimeout=function(_,fn) timeouts[#timeouts+1]=fn end
 promise.new=function() return {resolve=function(self,value) self.value=value end} end
 TriggerServerEvent=function(...) responses[#responses+1]=table.pack(...) end
 TriggerClientEvent=TriggerServerEvent
 ''')
 lua.execute((root/f'lib/callback/{side}.lua').read_text())
 if side=='client':
  lua.execute('''
   DT.Callback.Register('nilArgs',function(...) local args=table.pack(...);assert(args.n==3 and args[2]==7);return nil,7,nil end)
   handlers['DTlib:callback:client:request']('id','nilArgs',nil,7,nil)
   assert(responses[1].n==6 and responses[1][3]==true and responses[1][5]==7)
   Citizen.Await=function(waiter) timeouts[#timeouts]();return waiter.value end
   local ok,reason=pcall(DT.Callback.Await,'missing');assert(not ok and reason:find('callback_timeout:missing',1,true))
   Citizen.Await=function(waiter) handlers.onClientResourceStop('consumer');return waiter.value end
   ok,reason=pcall(DT.Callback.Await,'stopped');assert(not ok and reason:find('callback_resource_stopped',1,true))
  ''')
 else:
  lua.execute('''
   source=10
   DT.Callback.Register('nilArgs',function(src,...) local args=table.pack(...);assert(src==10 and args.n==3 and args[2]==7);return nil,7,nil end)
   handlers['DTlib:callback:server:request']('id','nilArgs',nil,7,nil)
   assert(responses[1].n==7 and responses[1][4]==true and responses[1][6]==7)
   Citizen.Await=function(waiter) timeouts[#timeouts]();return waiter.value end
   local ok,reason=pcall(DT.Callback.AwaitClient,10,'missing');assert(not ok and reason:find('callback_timeout:missing',1,true))
   Citizen.Await=function(waiter) source=10;handlers.playerDropped();return waiter.value end
   ok,reason=pcall(DT.Callback.AwaitClient,10,'dropped');assert(not ok and reason:find('callback_player_dropped',1,true))
   Citizen.Await=function(waiter)
    local id=responses[#responses][3]
    source=11;handlers['DTlib:callback:client:response'](id,true,'forged');assert(not waiter.value)
    source=10;handlers['DTlib:callback:client:response'](id,true,'valid');return waiter.value
   end
   assert(DT.Callback.AwaitClient(10,'auth')=='valid')
  ''')
print('Callback nil arguments/results, timeout, disconnect, stop and response source validation PASS')
# Exports simulate Cfx's function(self, ...) wrapper exactly.
for mode in ['setter','toggle']:
 lua=runtime(resources=['DT_temperature'])
 lua.globals().testMode=mode
 lua.execute('''
 visible=true;toggleCount=0;setValues={}
 LocalPlayer.state.set=function(self,key,value) self[key]=value end
 function DisplayHud(...) end;function DisplayRadar(...) end;function IsHudHidden() return false end;function IsRadarHidden() return false end
 local handle={}
 exports=setmetatable({}, {__index=function(_,resource)
  if resource~='DT_temperature' then error('missing resource') end
  return setmetatable(handle,{__index=function(_,method)
   if method=='IsVisible' then return function(self) assert(self==handle);return visible end end
   if method=='SetVisible' and testMode=='setter' then return function(self,value) assert(self==handle and type(value)=='boolean');visible=value;setValues[#setValues+1]=value end end
   if method=='ToggleVisible' and testMode=='toggle' then return function(self) assert(self==handle);toggleCount=toggleCount+1;visible=not visible end end
   error('missing export')
  end})
 end,__call=function() end})
 ''')
 lua.execute((root/'modules/ui_suspend/client.lua').read_text())
 lua.execute('''
 local token=DT.UI.Suspend('placement');assert(not visible)
 assert(DT.UI.Resume(token) and visible)
 local retry=threads[#threads];retry();assert(visible)
 if testMode=='toggle' then assert(toggleCount==2) else assert(setValues[1]==false) end
 local unrelated=DT.UI.Suspend('inventory');local placement=DT.UI.Suspend('placement')
 DT.UI.RestorePlacement(true);assert(DT.UI.IsSuspended())
 DT.UI.Resume(unrelated);assert(not DT.UI.IsSuspended())
 ''')
print('Cfx export arguments, single toggle restore, delayed retries and nested UI suspension PASS')
lua=runtime()
lua.execute('''
 frozen={[1]=false,[2]=false,[3]=true,[100]=true};ped=1;nativeOptions=nil
 function PlayerPedId() return ped end
 function IsEntityPositionFrozen(entity) return frozen[entity] or false end
 function FreezeEntityPosition(entity,value) frozen[entity]=value end
 function SetEntityVelocity(...) end
 function NetworkGetEntityIsNetworked(...) return false end
 function GetEntityRotation(...) return vec3(0,0,0) end
 function GetEntityHeading(...) return 0 end
 function DisableAllControlActions(...) end;function DisableControlAction(...) end
 function DisablePlayerFiring(...) end;function ClearPedSecondaryTask(...) end
 function IsPedInMeleeCombat(...) return false end;IsPedShooting=IsPedInMeleeCombat;IsPedReloading=IsPedInMeleeCombat
 function SetPauseMenuActive(...) end
 DT.UI={};DT.TextUI={}
 TriggerEvent=function(name,entity,id,options) if name=='DTlib:gizmo:start' then nativeOptions=options end end
''')
lua.execute((root/'modules/placement/dtlib/client.lua').read_text())
lua.execute('''
 Citizen.Await=function()
  assert(nativeOptions.freezePlayer==true and nativeOptions.managePlayerFreeze==false)
  ped=2;local thread=coroutine.create(threads[#threads]);Wait=function() coroutine.yield() end
  assert(coroutine.resume(thread));assert(frozen[2])
  ped=3;return {confirmed=true,cancelled=false}
 end
 local result=DT.Placement.Edit(100,{hideUI=false,showHelp=false})
 assert(result.confirmed and frozen[1]==false and frozen[2]==false and frozen[3]==true and frozen[100]==true)
 ped=1;frozen[1]=true
 Citizen.Await=function() return {confirmed=false,cancelled=true} end
 result=DT.Placement.Edit(100,{hideUI=false,showHelp=false});assert(result.cancelled and frozen[1]==true)
 frozen[1]=false
 result=DT.Placement.Edit(100,{hideUI=false,showHelp=false,freezePlayer=false})
 assert(nativeOptions.freezePlayer==false and not frozen[1])
''')
print('Placement confirms/cancels, PED changes, original freeze state and freezePlayer=false PASS')

lua=runtime()
lua.execute("""
 fallbackShown=0;fallbackHidden=0
 DTConfig.UI.textUIPosition='offcenter-right'
 DT.UI.Adapter=function() return {show=function() return false end,hide=function() return false end} end
 DT.Modules.Register('helptext','native',{show=function() fallbackShown=fallbackShown+1;return true end,hide=function() fallbackHidden=fallbackHidden+1;return true end})
""")
lua.execute((root/'modules/helptext/client.lua').read_text())
lua.execute("assert(DT.TextUI.Show('Fallback') and fallbackShown==1);assert(DT.TextUI.Hide() and fallbackHidden==1);assert(DT.TextUI.GetState()==nil)")
print('TextUI false-result native fallback and state cleanup PASS')
