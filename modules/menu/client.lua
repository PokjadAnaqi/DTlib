local menuItems={}; local menuCallback; local menuId=0; local activeId; local activeProvider
local function providerName() local n=DT.UI.Name(); return n=='lation_ui' and 'lation_ui' or n=='ox_lib' and 'ox_lib' or 'native' end
local function provider() return DT.UI.Adapter('menu') end
local function execute(index)
    local item=menuItems[index]; if not item or item.disabled or item.readOnly then return end; local cb=menuCallback; if DTUtils.isCallable(item.onSelect) then DTUtils.safeCall(item.onSelect,item,index) end; if DTUtils.isCallable(cb) then DTUtils.safeCall(cb,item,index) end; if item.event then TriggerEvent(item.event,table.unpack(item.args or {})) end; if item.serverEvent then TriggerServerEvent(item.serverEvent,table.unpack(item.args or {})) end; if item.command then ExecuteCommand(item.command) end
    if item.shouldClose~=false and item.close~=false then menuItems={}; menuCallback=nil; activeId=nil; activeProvider=nil end
end
function DT.Menu.Open(data,cb)
    data=data or {}; menuId=menuId+1; menuItems=data.items or data.options or {}; menuCallback=cb or data.onSelect; activeId=tostring(data.id or ('dtlib_menu_%s'):format(menuId)); activeProvider=provider()
    local function onExit() local fn=data.onExit; menuItems={}; menuCallback=nil; activeId=nil; activeProvider=nil; if DTUtils.isCallable(fn) then DTUtils.safeCall(fn) end end
    local ok,result=pcall(activeProvider.open,activeProvider,activeId,data,menuItems,execute,onExit); if ok then return result end
    DT.Debug('Menu provider failed, using native:',result); activeProvider=DT.Modules.Get('menu','native'); return activeProvider:open(activeId,data,menuItems,execute,onExit)
end
function DT.Menu.Close() if activeProvider and activeProvider.close then pcall(activeProvider.close,activeProvider) else local n=DT.Modules.Get('menu','native'); if n then n:close() end end; menuItems={}; menuCallback=nil; activeId=nil; activeProvider=nil end
RegisterNUICallback('menuSelect',function(data,cb) cb({ok=true}); local i=tonumber(data and data.index); local item=i and menuItems[i]; if not item or item.disabled then return end; local shouldClose=item.shouldClose~=false and item.close~=false; if shouldClose then SetNuiFocus(false,false); SendNUIMessage({action='menu:close',data={}}) end; execute(i) end)
RegisterNUICallback('menuClose',function(_,cb) cb({ok=true}); DT.Menu.Close() end)
exports('MenuOpen',function(...) return DT.Menu.Open(...) end); exports('MenuClose',function(...) return DT.Menu.Close(...) end)
