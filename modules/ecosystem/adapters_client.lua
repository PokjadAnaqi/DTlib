-- Adapt bundled community signatures to the existing DT contracts.
local E=DT.Ecosystem
local function reg(category,p,adapter)
    if p.default or DT.Modules.Get(category,p.resource) then return end
    adapter.resource=p.resource;adapter.publicName=p.resource
    function adapter:available() return DTConfig.Ecosystem.enabled~=false and DTUtils.isStarted(self.resource) end
    DT.Modules.Register(category,p.resource,adapter)
end
for _,p in ipairs(DTEcosystemCatalog.notify.providers) do
    local name=p.name
    reg('notify',p,{send=function(_,d)
        local a,err=E.Get('notify',name);if not a then error(err) end
        a.SendNotification(d.title,d.message or d.description,d.type,d.duration,d);return true
    end})
end
for _,p in ipairs(DTEcosystemCatalog.helptext.providers) do
    local name=p.name;local shown=false;local text
    reg('helptext',p,{show=function(_,d)
        local a,err=E.Get('helptext',name);if not a then error(err) end
        text=d.description or d.text or '';a.ShowHelpText(text,d.position);shown=true;return true
    end,hide=function()
        local a,err=E.Get('helptext',name);if not a then error(err) end
        a.HideHelpText();shown=false;text=nil;return true
    end,isOpen=function() return shown,text end})
end
for _,p in ipairs(DTEcosystemCatalog.progressbar.providers) do
    local name=p.name
    reg('progressbar',p,{run=function(_,d)
        local a,err=E.Get('progressbar',name);if not a then error(err) end
        return a.Open(d,nil,false)
    end})
end
for _,p in ipairs(DTEcosystemCatalog.input.providers) do
    local name=p.name
    reg('input',p,{await=function(_,d,fields)
        local a,err=E.Get('input',name);if not a then error(err) end
        return a.Open(d.title or 'INPUT',fields,false,d.submitText)
    end,close=function() return false,'unsupported_backend' end})
end
for _,p in ipairs(DTEcosystemCatalog.menu.providers) do
    local name=p.name
    reg('menu',p,{open=function(_,id,d,items,select,onExit)
        local a,err=E.Get('menu',name);if not a then error(err) end
        local opts={}
        for i,item in ipairs(items) do
            local index=i;opts[i]=DTUtils.copy(item);opts[i].title=item.title or item.label
            opts[i].onSelect=function() select(index) end
        end
        a.Open({id=id,title=d.title or 'MENU',options=opts,onExit=onExit,canClose=d.canClose,position=d.position},false)
        return id
    end,close=function(self)
        if self.resource=='qb-menu' then exports['qb-menu']:closeMenu();return true end
        if self.resource=='wasabi_uikit' then exports.wasabi_uikit:hideContext(false);return true end
        return false,'unsupported_backend'
    end})
end
local aliases={lation='lation_ui',lationui='lation_ui',ox='ox_lib',oxlib='ox_lib',okoktextui='okokTextUI',okok='okokTextUI',dt='native',dtlib='native',['qb-progressbar']='progressbar',zsxui='ZSX_UIV2'}
function DT.UI.Adapter(category,override)
    local key=({helptext='textui',progressbar='progress'})[category] or category
    local configured=override or DTConfig.Adapters[key]
    if not configured or configured=='auto' then configured=DTConfig.Adapters.ui or 'auto' end
    if configured=='disabled' or configured=='none' then configured='native' end
    local candidates={}
    for _,n in ipairs({'lation_ui','ox_lib','okokTextUI'}) do if DT.Modules.Get(category,n) then candidates[#candidates+1]=n end end
    local c=DTEcosystemCatalog[category]
    if c then for _,p in ipairs(c.providers) do if not p.default and not DTUtils.tableContains(candidates,p.resource) then candidates[#candidates+1]=p.resource end end end
    return DT.Modules.Resolve(category,configured,candidates,aliases,'native')
end
