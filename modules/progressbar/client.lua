local function providerName() local n=DT.UI.Name(); return n=='lation_ui' and 'lation_ui' or n=='ox_lib' and 'ox_lib' or 'native' end
local active=false; local current=nil
local cachedAdapter, cachedKey, cachedResolver
local backendActive, nextActiveCheck = false, 0
local function invalidate()
    cachedAdapter, cachedKey, cachedResolver = nil, nil, nil
    backendActive, nextActiveCheck = false, 0
end
local function A()
    local adapters = DTConfig.Adapters or {}
    local key = tostring(adapters.progress)..':'..tostring(adapters.ui)..':'..tostring(DTConfig.Ecosystem and DTConfig.Ecosystem.enabled)
    if not cachedAdapter or key ~= cachedKey or cachedResolver ~= DT.UI.Adapter then
        backendActive, nextActiveCheck = false, 0
        cachedAdapter = DT.UI.Adapter('progressbar')
        cachedKey, cachedResolver = key, DT.UI.Adapter
    end
    return cachedAdapter
end
AddEventHandler('onClientResourceStart', invalidate)
AddEventHandler('onClientResourceStop', invalidate)
AddEventHandler('DTlib:progress:state', function() nextActiveCheck = 0 end)
function DT.Progress(data)
    if active then return false,'busy' end; data=DTUtils.copy(data or {}); active=true; TriggerEvent('DTlib:progress:state',true); current=A(); local ok,result=pcall(current.run,current,data); active=false; TriggerEvent('DTlib:progress:state',false); local name=current and current.publicName; current=nil
    if not ok and name~='native' then DT.Debug('Progress provider failed, using native:',result); local n=DT.Modules.Get('progressbar','native'); active=true; TriggerEvent('DTlib:progress:state',true); local ok2,r2=pcall(n.run,n,data); active=false; TriggerEvent('DTlib:progress:state',false); return ok2 and r2==true, ok2 and (r2==true and 'complete' or 'cancelled') or 'failed' end
    return ok and result==true, ok and (result==true and 'complete' or 'cancelled') or 'failed'
end
function DT.ProgressActive(force)
    if active then return true end
    local now = GetGameTimer()
    -- Backend polling remains for progress started outside DTlib. Confirm paths can bypass it.
    local a = A()
    if force == true or now >= nextActiveCheck then
        backendActive = a and a.active and a:active() == true or false
        nextActiveCheck = now + 200
    end
    return backendActive
end
function DT.ProgressCancel() local a=current or A(); return a and a.cancel and a:cancel() or false end
exports('Progress',function(...) return DT.Progress(...) end); exports('ProgressActive',function(...) return DT.ProgressActive(...) end); exports('CancelProgress',function(...) return DT.ProgressCancel(...) end)
