local A={resource='native',publicName='native'}
local cancel=false
function A:available() return true end
function A:run(data)
    local duration=math.max(0,tonumber(data.duration) or 1000); local started=GetGameTimer(); cancel=false; local canCancel=data.canCancel~=false; local disable=data.disable or {}
    SendNUIMessage({action='progress:start',data={label=data.label or 'Processing...',duration=duration,position=data.position or DTConfig.UI.progressPosition}})
    local cancelled=false
    while GetGameTimer()-started<duration do Wait(0); if disable.move then DisableControlAction(0,30,true);DisableControlAction(0,31,true);DisableControlAction(0,21,true);DisableControlAction(0,22,true) end; if disable.sprint then DisableControlAction(0,21,true) end; if disable.car then for _,c in ipairs({59,60,63,64,71,72}) do DisableControlAction(0,c,true) end end; if disable.combat then for _,c in ipairs({24,25,140,141,142}) do DisableControlAction(0,c,true) end end; if disable.mouse then DisableControlAction(0,1,true);DisableControlAction(0,2,true) end; if cancel or (canCancel and IsControlJustReleased(0,200)) then cancelled=true; break end end
    SendNUIMessage({action='progress:stop',data={cancelled=cancelled}}); return not cancelled
end
function A:active() return false end
function A:cancel() cancel=true; SendNUIMessage({action='progress:stop',data={cancelled=true}}); return true end
DT.Modules.Register('progressbar','native',A)
