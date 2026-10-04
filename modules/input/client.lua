local waiter; local active=false; local activeProvider
local function providerName() local n=DT.UI.Name(); return n=='lation_ui' and 'lation_ui' or n=='ox_lib' and 'ox_lib' or 'native' end
local function provider() return DT.UI.Adapter('input') end
local function map(result,fields)
    if type(result)~='table' then return result end; local named=false; local out={}; for i=1,#(fields or {}) do local f=fields[i]; if f.name then out[f.name]=result[i]; named=true else out[i]=result[i] end end; return named and out or result
end
function DT.Input.Await(data)
    data=data or {}; if active or waiter then return nil,'busy' end; local fields=data.fields or data.options or {}; local a=DT.UI.Adapter('input',data.provider); activeProvider=a
    if a.publicName~='native' then active=true; local ok,result=pcall(a.await,a,data,fields); active=false; activeProvider=nil; if ok then return map(result,fields) end; DT.Debug('Input provider failed, using native:',result) end
    waiter=promise.new(); local n=DT.Modules.Get('input','native'); activeProvider=n; n:open(data,fields); local result=Citizen.Await(waiter); waiter=nil; activeProvider=nil; return result
end
function DT.Input.Close()
    if activeProvider and activeProvider.publicName~='native' and active then local ok,result=pcall(activeProvider.close,activeProvider); return ok and result~=false end
    if waiter then local n=DT.Modules.Get('input','native'); if n then n:close() end; waiter:resolve(nil); waiter=nil; activeProvider=nil; return true end; return false
end
RegisterNUICallback('inputSubmit',function(data,cb) cb({ok=true}); local n=DT.Modules.Get('input','native'); if n then n:close() end; if waiter then waiter:resolve(data and data.values or {}) end end)
RegisterNUICallback('inputCancel',function(_,cb) cb({ok=true}); local n=DT.Modules.Get('input','native'); if n then n:close() end; if waiter then waiter:resolve(nil) end end)
exports('InputAwait',function(...) return DT.Input.Await(...) end); exports('InputClose',function(...) return DT.Input.Close(...) end)
