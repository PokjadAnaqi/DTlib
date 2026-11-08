from harness import runtime, root
lua=runtime(resources=['qbx_core'])
lua.execute((root/'modules/framework/shared.lua').read_text())
lua.execute('''
clock=0;reads=0;rpcs=0;events={};work={};data={citizenid='A',job={name='police',grade=1},metadata={stress=2}}
function GetGameTimer() return clock end
function AddEventHandler(n,fn) events[n]=events[n] or {};table.insert(events[n],fn) end
RegisterNetEvent=AddEventHandler
function fire(n,...) for _,fn in ipairs(events[n] or {}) do fn(...) end end
function TriggerEvent(...) fire(...) end
function CreateThread(fn) work[#work+1]=fn end
function exportRead() reads=reads+1;if failExport then error('missing export') end;return data end
exports={qbx_core={GetPlayerData=function() return exportRead() end}}
DT.Callback.Await=function() rpcs=rpcs+1;return {citizenid='legacy'} end
''')
lua.execute((root/'modules/framework/qbx_core/dt_client.lua').read_text())
lua.execute('''
local a=DT.Modules.Get('framework','qbx_core')
for i=1,1000 do assert(a:getData().citizenid=='A') end
assert(reads==1 and rpcs==0)
fire('QBCore:Player:SetPlayerData',{citizenid='A',metadata={stress=10}})
assert(a:getData().metadata.stress==10 and reads==1)
fire('QBCore:Client:OnJobUpdate',{name='medic'});assert(a:getJob().name=='medic')
fire('QBCore:Client:OnGangUpdate',{name='none'});assert(a:getGang().name=='none')
fire('QBCore:Client:OnPlayerUnload');assert(next(a:getData())==nil)
fire('QBCore:Client:OnJobUpdate',{name='stale'});assert(next(a:getData())==nil)
data={citizenid='B'};fire('QBCore:Client:OnPlayerLoaded');assert(a:getData().citizenid=='B' and reads==2)
clock=60001;data={citizenid='B',metadata={stress=20}};assert(a:getData().metadata.stress==20 and reads==3)
fire('onClientResourceStop','qbx_core');assert(next(a:getData())==nil)
fire('onClientResourceStart','qbx_core');assert(a:getData().citizenid=='B' and reads==4)
-- Legacy fallback never yields/calls the RPC in getData; requests are coalesced.
failExport=true;fire('onClientResourceStart','qbx_core');local before=#work
for i=1,1000 do assert(next(a:getData())==nil) end
assert(reads==5 and rpcs==0 and #work==before+1)
work[#work]();assert(a:getData().citizenid=='legacy' and rpcs==1)
-- A late response must not overwrite an event update or a different session.
clock=clock+60001;fire('onClientResourceStart','qbx_core');a:getData()
DT.Callback.Await=function() rpcs=rpcs+1;fire('QBCore:Player:SetPlayerData',{citizenid='fresh'});return {citizenid='old'} end
work[#work]();assert(a:getData().citizenid=='fresh')
clock=clock+60001;fire('onClientResourceStart','qbx_core');a:getData()
DT.Callback.Await=function() fire('QBCore:Client:OnPlayerUnload');return {citizenid='old'} end
work[#work]();assert(next(a:getData())==nil)
-- Failed hydration retries are bounded, not per scan.
fire('onClientResourceStart','qbx_core');a:getData()
DT.Callback.Await=function() error('offline') end;work[#work]()
local count=#work;for i=1,1000 do a:getData() end;assert(#work==count)
clock=clock+5000;a:getData();assert(#work==count+1)
''')
print('QBX cache: 1000 reads/one export, no hot RPC; events, TTL, single flight, logout, late results and provider restart PASS')
