local menuItems,menuCallback,activeId,activeProvider,exitCallback={},nil,nil,nil,nil
local menuId=0
local canClose=true
local owner=nil
local function execute(index)
    local item=menuItems[index]
    if not item or item.disabled or item.readOnly then return end
    local callback=menuCallback
    if item.shouldClose~=false and item.close~=false then
        menuItems={};menuCallback=nil;activeId=nil;activeProvider=nil;exitCallback=nil
    end
    if DTUtils.isCallable(item.onSelect) then DTUtils.safeCall(item.onSelect,item,index) end
    if DTUtils.isCallable(callback) then DTUtils.safeCall(callback,item,index) end
    if item.event then TriggerEvent(item.event,table.unpack(item.args or {})) end
    if item.serverEvent then TriggerServerEvent(item.serverEvent,table.unpack(item.args or {})) end
    if item.command then ExecuteCommand(item.command) end
end
function DT.Menu.Open(data,callback)
    data=data or {};menuId=menuId+1
    canClose=data.canClose~=false;owner=GetInvokingResource() or GetCurrentResourceName()
    local id=tostring(data.id or ('dtlib_menu_%s'):format(menuId))
    menuItems=data.items or data.options or {};menuCallback=callback or data.onSelect
    activeId=id;activeProvider=DT.UI.Adapter('menu',data.provider)
    local exited=false
    local function onExit()
        if exited then return end;exited=true
        if activeId==id then menuItems={};menuCallback=nil;activeId=nil;activeProvider=nil;exitCallback=nil end
        if DTUtils.isCallable(data.onExit) then DTUtils.safeCall(data.onExit) end
    end
    exitCallback=onExit
    local ok,result=pcall(activeProvider.open,activeProvider,id,data,menuItems,execute,onExit)
    if ok then return result end
    DT.Debug('Menu provider failed, using native:',result)
    activeProvider=DT.Modules.Get('menu','native')
    return activeProvider:open(id,data,menuItems,execute,onExit)
end
function DT.Menu.Close()
    local provider,callback=activeProvider,exitCallback
    menuItems={};menuCallback=nil;activeId=nil;activeProvider=nil;exitCallback=nil
    provider=provider or DT.Modules.Get('menu','native')
    if provider and provider.close then pcall(provider.close,provider) end
    if callback then callback() end
end
RegisterNUICallback('menuSelect',function(data,callback)
    callback({ok=true})
    local index=tonumber(data and data.index);local item=index and menuItems[index]
    if not item or item.disabled or item.readOnly then return end
    if item.shouldClose~=false and item.close~=false then SetNuiFocus(false,false);SendNUIMessage({action='menu:close',data={}}) end
    execute(index)
end)
RegisterNUICallback('menuClose',function(_,callback) callback({ok=true});if canClose then DT.Menu.Close() end end)
exports('MenuOpen',function(...) return DT.Menu.Open(...) end)
exports('MenuClose',function(...) return DT.Menu.Close(...) end)

AddEventHandler('onClientResourceStop',function(resource)
    if activeId and (resource==owner or resource==GetCurrentResourceName()) then DT.Menu.Close() end
end)
