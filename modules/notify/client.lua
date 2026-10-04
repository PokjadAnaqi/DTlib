local aliases={lation='lation_ui',lationui='lation_ui',ox='ox_lib',oxlib='ox_lib',okok='okokNotify',okoknotify='okokNotify',dt='native',dtlib='native'}
local function A()
    local configured=DTConfig.Adapters.notify or 'auto'
    local candidates={'lation_ui','ox_lib','okokNotify'}
    for _,p in ipairs(DTEcosystemCatalog.notify.providers) do if not p.default and not DTUtils.tableContains(candidates,p.resource) then candidates[#candidates+1]=p.resource end end
    return DT.Modules.Resolve('notify',configured,candidates,aliases,'native')
end
function DT.NotifyProvider() local a=A(); return a and a.publicName or 'native' end
function DT.Notify(data,description,notifyType)
    local p=DT.NotifyUtil.payload(data,description,notifyType); local a=A();
    if a and a.send then local ok,err=pcall(a.send,a,p); if ok and err~=false then return true end; DT.Debug('Notify provider failed, using native:',err) end
    local n=DT.Modules.Get('notify','native'); return n and n:send(p) or false
end
RegisterNetEvent('DTlib:client:notify',function(data) DT.Notify(data) end)
exports('Notify',function(...) return DT.Notify(...) end)
