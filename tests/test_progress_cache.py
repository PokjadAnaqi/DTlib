from harness import runtime, root
lua=runtime()
lua.execute('''
clock=0;resolves=0;polls=0;busy=false;events={};DT.UI={}
function GetGameTimer() return clock end
function AddEventHandler(n,fn) events[n]=events[n] or {};table.insert(events[n],fn) end
function fire(n,...) for _,fn in ipairs(events[n] or {}) do fn(...) end end
exports=function() end
DT.UI.Adapter=function(category) resolves=resolves+1;return {resource='native',active=function() polls=polls+1;return busy end,run=function() assert(DT.ProgressActive());return true end} end
''')
lua.execute((root/'modules/progressbar/client.lua').read_text())
lua.execute('''
for i=1,1000 do assert(not DT.ProgressActive()) end
assert(resolves==1 and polls==1)
busy=true;assert(DT.ProgressActive(true) and polls==2)
busy=false;assert(DT.ProgressActive()) -- bounded snapshot, confirm bypasses it
assert(not DT.ProgressActive(true))
clock=200;assert(not DT.ProgressActive() and resolves==1)
DTConfig.Adapters.ui='native';DT.ProgressActive();assert(resolves==2)
fire('onClientResourceStop','native');DT.ProgressActive();assert(resolves==3)
fire('onClientResourceStart','native');DT.ProgressActive();assert(resolves==4)
assert(DT.Progress({duration=1})==true)
''')
print('Progress: one resolution/one backend query for 1000 hot reads; forced confirm, TTL, config and provider invalidation PASS')
