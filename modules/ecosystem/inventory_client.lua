local function call(provider,method,...)
    local a,err=DT.Ecosystem.Get('inventory',provider)
    if not a then return nil,err end
    if not DTUtils.isCallable(a[method]) then return nil,'unsupported_backend' end
    return a[method](...)
end
for _,p in ipairs(DTEcosystemCatalog.inventory.providers) do
    if not p.default and not DT.Modules.Get('inventory',p.resource) then
        local name=p.name
        local A={resource=p.resource,publicName=p.resource}
        function A:available() return DTConfig.Ecosystem.enabled~=false and DTUtils.isStarted(self.resource) end
        function A:getCount(...) return call(name,'GetItemCount',...) end
        function A:getItems(...) return call(name,'GetPlayerInventory',...) end
        function A:getItemData(...) return call(name,'GetItemInfo',...) end
        function A:open(kind,id)
            local a,err=DT.Ecosystem.Get('inventory',name)
            if not a then return nil,err end
            if type(a.OpenInventory)=='function' then return a.OpenInventory(kind,id) end
            return nil,'unsupported_backend'
        end
        DT.Modules.Register('inventory',p.resource,A)
    end
end
