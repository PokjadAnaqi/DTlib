DT.ListMenu=DT.ListMenu or {}
local menus={};local active;local sequence=0
local function backend()
    local configured=DTConfig.Adapters.listmenu
    if not configured or configured=='auto' then configured=DTConfig.Adapters.ui or 'auto' end
    local aliases={lation='lation_ui',lationui='lation_ui',ox='ox_lib',oxlib='ox_lib'}
    configured=aliases[configured] or configured
    if configured=='native' or configured=='dtlib' then return nil end
    return DTUtils.detect(configured,{'lation_ui','ox_lib'})
end
local function exportCall(provider,method,...)
    if not provider or not DTUtils.isStarted(provider) then error('provider_unavailable') end
    local args=table.pack(...)
    return exports[provider][method](exports[provider],table.unpack(args,1,args.n))
end
local methods={lation_ui={register='registerListMenu',show='showListMenu',hide='hideListMenu',set='setListMenuOptions',get='getOpenListMenu'},ox_lib={register='registerMenu',show='showMenu',hide='hideMenu',set='setMenuOptions',get='getOpenMenu'}}
local function callback(fn) return DTUtils.wrapCallable(fn) end
function DT.ListMenu.Register(data,cb)
    assert(type(data)=='table' and type(data.id)=='string','DT.ListMenu.Register requires a string id')
    local p=backend(); if not p then return nil,'provider_unavailable' end
    local d=DTUtils.copy(data);d.options=d.options or d.items or {};d.items=nil
    d.position=d.position or 'top-right'
    if d.position=='offcenter-right' or d.position=='right-center' then d.position='top-right' end
    if d.position=='offcenter-left' or d.position=='left-center' then d.position='top-left' end
    local options=d.options
    local dispatch=callback(cb)
    for _,key in ipairs({'onClose','onSelected','onSideScroll','onCheck'}) do d[key]=callback(d[key]) end
    local close=d.onClose
    d.onClose=function(key) active=nil; if close then close(key) end end
    for i,item in ipairs(options) do
        item.label=item.label or item.title or ('Option %d'):format(i)
        item.close=item.close~=false and item.shouldClose~=false
        item.disabled=item.disabled==true or item.readOnly==true
        -- Central dispatch below executes selections once for both backends.
        item.onSelect=nil;item.event=nil;item.serverEvent=nil
    end
    local originals=data.options or data.items or {}
    local function select(index,scroll,args,checked)
        local item=originals[index]
        if not item or item.disabled or item.readOnly then return end
        if item.close~=false and item.shouldClose~=false then active=nil end
        if DTUtils.isCallable(item.onSelect) then DTUtils.safeCall(item.onSelect,index,scroll,args,checked) end
        if dispatch then dispatch(index,scroll,args,checked) end
        if item.event then TriggerEvent(item.event,args) end
        if item.serverEvent then TriggerServerEvent(item.serverEvent,args) end
        if item.command then ExecuteCommand(item.command) end
    end
    local ok,err=pcall(exportCall,p,methods[p].register,d,select)
    if not ok then return nil,tostring(err) end
    menus[data.id]={provider=p,data=d,callback=select,originals=originals}
    return data.id
end
function DT.ListMenu.Show(id,startIndex)
    local m=menus[id];if not m then return false,'unknown_menu' end
    local ok,err=pcall(exportCall,m.provider,methods[m.provider].show,id,startIndex)
    if not ok then return false,tostring(err) end
    active=id;return true
end
function DT.ListMenu.Open(data,cb)
    sequence=sequence+1;data=DTUtils.copy(data or {});data.id=data.id or ('dtlib_list_%d'):format(sequence)
    local id,err=DT.ListMenu.Register(data,cb);if not id then return nil,err end
    local ok,reason=DT.ListMenu.Show(id,data.startIndex);return ok and id or nil,reason
end
function DT.ListMenu.Close(onExit)
    local m=active and menus[active];if not m then return false end
    local ok,err=pcall(exportCall,m.provider,methods[m.provider].hide,onExit==true)
    if ok then active=nil;return true end;return false,tostring(err)
end
function DT.ListMenu.SetOptions(id,options,index)
    local m=menus[id];if not m then return false,'unknown_menu' end
    if index then m.originals[index]=options else
        for key in pairs(m.originals) do m.originals[key]=nil end
        for key,value in pairs(options) do m.originals[key]=value end
    end
    -- Reuse the original table referenced by the registration callback.
    if index then m.data.options[index]=DTUtils.copy(options) else m.data.options=DTUtils.copy(options) end
    local list=index and {m.data.options[index]} or m.data.options
    for _,item in ipairs(list) do item.label=item.label or item.title;item.disabled=item.disabled==true or item.readOnly==true;item.close=item.close~=false and item.shouldClose~=false;item.onSelect=nil;item.event=nil;item.serverEvent=nil end
    local ok,err=pcall(exportCall,m.provider,methods[m.provider].set,id,index and m.data.options[index] or m.data.options,index)
    return ok,not ok and tostring(err) or nil
end
function DT.ListMenu.GetOpen()
    local m=active and menus[active];if not m then return nil end
    local ok,result=pcall(exportCall,m.provider,methods[m.provider].get)
    if ok then active=result;return result end
end
DT.ListMenu.Provider=backend
DT.UI.ListMenu=DT.ListMenu.Open
for name,method in pairs({RegisterListMenu='Register',ShowListMenu='Show',ListMenuOpen='Open',HideListMenu='Close',SetListMenuOptions='SetOptions',GetOpenListMenu='GetOpen'}) do
    local fn=method;exports(name,function(...) return DT.ListMenu[fn](...) end)
end
