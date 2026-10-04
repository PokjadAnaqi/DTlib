local U = DT.FrameworkUtil
local A = { resource = 'ox_core', publicName = 'ox' }
local function call(method, ...)
    local args={...}; local ok,a,b,c=pcall(function() return exports.ox_core:CallPlayer(method, table.unpack(args)) end)
    if not ok then return nil end
    return a,b,c
end
local function pair(method, ...)
    local a,b=call(method,...); if type(a)=='table' and b==nil then return a[1],a[2] end; return a,b
end
local function groupDef(name) local ok,d=pcall(function() return GlobalState[('group.%s'):format(name)] end); return ok and d or nil end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getData()
    local ok,data=pcall(function() return exports.ox_core:GetPlayer() end); if not ok or type(data)~='table' then data={} end
    data.name=call('get','name'); data.activeGroup=call('get','activeGroup'); data.groups=call('getGroups') or {}; return data
end
function A:getJob() local n,g=pair('getGroupByType','job'); return n and U.normalizeGroup(groupDef(n),n,g) or nil end
function A:getGang() local n,g=pair('getGroupByType','gang'); return n and U.normalizeGroup(groupDef(n),n,g) or nil end
function A:getGroups() local g=call('getGroups'); return type(g)=='table' and g or {} end
function A:getGroup(filter) return pair('getGroup', filter) end
function A:hasGroup(filter) local g=self:getGroup(filter); return g~=nil and g~=false end
function A:hasPrimaryGroup(filter)
    local active=call('get','activeGroup'); if not active then return false end
    local groups=self:getGroups(); return U.filterMatch({[active]=groups[active] or 0},filter)
end
function A:getMeta(key) return call('get',key) end
function A:getStatus(status) return call('getStatus',status) end
function A:getCoords() return call('getCoords') or GetEntityCoords(PlayerPedId()) end
function A:hasPermission(permission) local v=call('hasPermission',permission); return v==true end
function A:getName() return call('get','name') or GetPlayerName(PlayerId()) end

DT.Modules.Register('framework', 'ox_core', A)
