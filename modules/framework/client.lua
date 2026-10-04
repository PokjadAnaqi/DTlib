local U = DT.FrameworkUtil
local candidates = {'qbx_core','qb-core','es_extended','ox_core'}
local function adapter()
    return DT.Modules.Resolve('framework', DTConfig.Adapters.framework, candidates, U.aliases, 'standalone')
end

function DT.Framework.Name() local a=adapter(); return a and a.publicName or 'standalone' end
function DT.Framework.Resource() local a=adapter(); return a and a.resource ~= 'standalone' and a.resource or nil end
function DT.Framework.Available(name)
    if not name then return DT.Framework.Resource() ~= nil end
    name=tostring(name):lower(); name=U.aliases[name] or name; return DTUtils.isStarted(name)
end
function DT.Framework.GetVersion()
    local a=adapter(); if not a or a.resource=='standalone' then return nil end
    if a.resource=='qbx_core' then local ok,v=pcall(function() return exports.qbx_core:GetCoreVersion(GetCurrentResourceName()) end); if ok and v then return v end end
    return U.resourceVersion(a.resource)
end
function DT.Player.GetData() local a=adapter(); return a and a.getData and a:getData() or {} end
function DT.Player.GetServerId() return GetPlayerServerId(PlayerId()) end
function DT.Player.GetName() local a=adapter(); return a and a.getName and a:getName() or GetPlayerName(PlayerId()) end
function DT.Player.GetJob() local a=adapter(); return a and a.getJob and a:getJob() or nil end
function DT.Player.GetGang() local a=adapter(); return a and a.getGang and a:getGang() or nil end
function DT.Player.GetGroups() local a=adapter(); return a and a.getGroups and a:getGroups() or {} end
function DT.Player.GetGroup(filter)
    local a=adapter(); if a and a.getGroup then return a:getGroup(filter) end
    local groups=DT.Player.GetGroups(); if type(filter)=='string' then return groups[filter] end
    for name,grade in pairs(groups) do if U.filterMatch({[name]=grade},filter) then return name,grade end end
end
function DT.Player.HasGroup(filter)
    local a=adapter(); if a and a.hasGroup then return a:hasGroup(filter) end
    return U.filterMatch(DT.Player.GetGroups(),filter)
end
function DT.Player.HasPrimaryGroup(filter)
    local a=adapter(); if a and a.hasPrimaryGroup then return a:hasPrimaryGroup(filter) end
    local groups={}; local job,gang=DT.Player.GetJob(),DT.Player.GetGang(); if job and job.name then groups[job.name]=job.grade end; if gang and gang.name then groups[gang.name]=gang.grade end
    return U.filterMatch(groups,filter)
end
function DT.Player.GetMeta(key) local a=adapter(); return a and a.getMeta and a:getMeta(key) or nil end
function DT.Player.GetStatus(status) local a=adapter(); return a and a.getStatus and a:getStatus(status) or nil end
function DT.Player.GetCoords() local a=adapter(); return a and a.getCoords and a:getCoords() or GetEntityCoords(PlayerPedId()) end
function DT.Player.HasPermission(permission) local a=adapter(); return a and a.hasPermission and a:hasPermission(permission) or false end
