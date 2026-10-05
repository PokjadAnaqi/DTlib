local A={resource='native',publicName='native'}
function A:available() return true end
function A:send(p)
    local data=DTUtils.copy(p);data.description=p.message or '';data.title=p.title or '';
    SendNUIMessage({action='notify',data=data}); return true
end
DT.Modules.Register('notify','native',A)
