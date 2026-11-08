from harness import runtime, root

lua = runtime()
lua.execute('''
now=1000;coordsReads=0;enters=0;exits=0;insideTicks=0;position={x=0,y=0,z=0}
function GetGameTimer() return now end
function PlayerPedId() return 1 end
function GetEntityCoords() coordsReads=coordsReads+1;return position end
function Wait(ms) coroutine.yield(ms) end
''')
lua.execute((root/'modules/zones/client.lua').read_text())
lua.execute('''
local loop=coroutine.create(threads[#threads])
local function step(expected) local ok,ms=coroutine.resume(loop);assert(ok,ms);assert(ms==expected) end
step(1000);assert(coordsReads==0)
local function zone() return DT.Zone.Box({coords={x=0,y=0,z=0},size={x=4,y=4,z=4},
onEnter=function() enters=enters+1 end,onExit=function() exits=exits+1 end,
inside=function() insideTicks=insideTicks+1 end}) end
local a,b=zone(),zone();step(100);assert(coordsReads==1 and enters==2 and insideTicks==2)
now=1100;step(100);assert(coordsReads==1)
now=1300;position={x=20,y=0,z=0};step(100);assert(coordsReads==2 and exits==2)
DT.Zone.Remove(a);DT.Zone.Remove(b);step(1000);assert(coordsReads==2)
''')
print('Zone idle skips natives; due zones share one position read; enter/inside/exit/removal PASS')

lua = runtime()
lua.execute('''
DTConfig.Waypoint={enabled=true};threads={};camReads=0
function RegisterCommand() end
function GetFinalRenderedCamCoord() camReads=camReads+1;return vec3(0,0,0) end
function Wait(ms) coroutine.yield(ms) end
''')
lua.execute((root/'modules/waypoint/dtlib/client.lua').read_text())
lua.execute('''
-- Thread 1 requests server sync; thread 2 selects visible waypoints.
local loop=coroutine.create(threads[2])
for i=1,5 do local ok,ms=coroutine.resume(loop);assert(ok,ms);assert(ms==500) end
assert(camReads==0)
''')
print('Empty waypoint visibility scan sleeps without camera/native calls PASS')
