-- Legacy source-pack Target API. Actions retain its entity-only callback contract.
Target=Target or {}
local function owner() return GetInvokingResource() or GetCurrentResourceName() end
function Target.GetResourceName() return 'DT_interact' end
function Target.FixOptions(list)
    local out={}
    for _,raw in ipairs(list or {}) do
        local o={};for k,v in pairs(raw) do o[k]=v end
        local action=raw.onSelect or raw.action
        if action then o.onSelect=function(data) return action(data.entity) end;o.action=nil end
        if o.type=='server' then o.serverEvent=o.event;o.event=nil elseif o.type=='command' then o.command=o.event;o.event=nil end
        o.groups=o.groups or o.job;o.items=o.items or o.item
        out[#out+1]=o
    end;return out
end
for _,kind in ipairs({'Ped','Player','Vehicle','Object'}) do local k=kind
    Target['AddGlobal'..k]=function(list) local h=exports.DT_interact;return h['addGlobal'..k](h,Target.FixOptions(list),owner()) end
    Target['RemoveGlobal'..k]=function(names) local h=exports.DT_interact;return h['removeGlobal'..k](h,names,owner()) end
end
for public,backend in pairs({LocalEntity='LocalEntity',NetworkedEntity='Entity',Model='Model'}) do local k=backend
    Target['Add'..public]=function(values,list) local h=exports.DT_interact;return h['add'..k](h,values,Target.FixOptions(list),owner()) end
    Target['Remove'..public]=function(values,names) local h=exports.DT_interact;return h['remove'..k](h,values,names,owner()) end
end
function Target.AddSphereZone(name,coords,radius,options,debug) return exports.DT_interact:addSphereZone({name=name,coords=coords,radius=radius,options=Target.FixOptions(options),debug=debug},owner()) end
function Target.AddBoxZone(name,coords,size,heading,options,debug) return exports.DT_interact:addBoxZone({name=name,coords=coords,size=size,rotation=heading,options=Target.FixOptions(options),debug=debug},owner()) end
function Target.RemoveZone(id) return exports.DT_interact:removeZone(id,true,owner()) end
function Target.DisableTargeting(value) return exports.DT_interact:disableTargeting(value) end
