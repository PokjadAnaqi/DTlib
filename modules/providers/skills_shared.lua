local P=DT.Providers
local config,experience={},{}
local spec={evolent_skills={'getSkillLevel','addXp','removeXp'},OT_skills={'getSkill','addXP','removeXP'},pickle_xp={'GetPlayerLevel','AddPlayerXP','RemovePlayerXP'}}
local function create(name,maxLevel,base,scale)
    assert(type(name)=='string' and name~='','invalid_skill')
    config[name]={maxLevel=math.max(1,tonumber(maxLevel) or 99),base=math.max(1,tonumber(base) or 50),scale=math.max(1,tonumber(scale) or 1.1)}
    return config[name]
end
local function threshold(name,level)
    local c=config[name] or create(name);local xp=0
    for i=1,math.max(0,math.min(c.maxLevel,tonumber(level) or 1)-1) do xp=xp+math.floor(c.base*c.scale^(i-1)) end
    return xp
end
for _,definition in ipairs(DTEcosystemCatalog.skills.providers) do
    P.Register('skills',definition.resource,function(resource)
        local api={Create=create,GetXPForLevel=threshold,GetXPRequiredForLevel=threshold}
        if not P.Server then
            function api.GetSkillLevel(name) return DT.Callback.Await('DTlib:provider:skillLevel',resource,name) end
            if resource=='native' then function api.GetXP(name) return DT.Callback.Await('DTlib:provider:skillXP',name) end end
            return api
        end
        local vendor=spec[resource]
        if vendor then
            function api.GetSkillLevel(src,name) local value=P.Export(resource,vendor[1],src,name);return type(value)=='table' and value.level or value end
            api.AddXp=P.Bind(resource,vendor[2]);api.RemoveXp=P.Bind(resource,vendor[3]);api.AddXP=api.AddXp
        else
            function api.GetXP(src,name) return (experience[src] or {})[name] or 0 end
            function api.SetXP(src,name,value)
                value=tonumber(value);if not value or value<0 or value==math.huge or value~=value then return false,'invalid_xp' end
                experience[src]=experience[src] or {};experience[src][name]=value;return true
            end
            function api.AddXP(src,name,value) value=tonumber(value);if not value or value<0 then return false,'invalid_xp' end;return api.SetXP(src,name,api.GetXP(src,name)+value) end
            api.AddXp=api.AddXP
            function api.RemoveXp(src,name,value) value=tonumber(value);if not value or value<0 then return false,'invalid_xp' end;return api.SetXP(src,name,math.max(0,api.GetXP(src,name)-value)) end
            function api.GetSkillLevel(src,name)
                local c=config[name] or create(name);local xp=api.GetXP(src,name);local level=1
                while level<c.maxLevel and xp>=threshold(name,level+1) do level=level+1 end;return level
            end
            function api.SetSkillLevel(src,name,level) return api.SetXP(src,name,threshold(name,level)) end
            function api.GetScaledXP(name,level) local c=config[name] or create(name);return math.floor(c.base*c.scale^(math.max(1,level)-1)) end
        end
        return api
    end)
end
if P.Server then
    DT.Callback.Register('DTlib:provider:skillLevel',function(src,resource,name) local api=DT.Ecosystem.Get('skills',resource);return api and api.GetSkillLevel(src,name) end)
    DT.Callback.Register('DTlib:provider:skillXP',function(src,name) local api=DT.Ecosystem.Get('skills','native');return api.GetXP(src,name) end)
    AddEventHandler('playerDropped',function() experience[source]=nil end)
end
