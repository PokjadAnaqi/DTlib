local A={resource='native',publicName='native'}
function A:available() return true end
function A:send(p)
    SendNUIMessage({action='notify',data={title=p.title or 'DT SYSTEM',description=p.message or '',type=p.type,duration=p.duration,position=p.position,icon=p.icon}}); return true
end
DT.Modules.Register('notify','native',A)
