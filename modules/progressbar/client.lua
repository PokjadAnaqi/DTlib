local function providerName() local n=DT.UI.Name(); return n=='lation_ui' and 'lation_ui' or n=='ox_lib' and 'ox_lib' or 'native' end
local active=false; local current=nil
local function A() return DT.UI.Adapter('progressbar') end
function DT.Progress(data)
    if active then return false,'busy' end; data=DTUtils.copy(data or {}); active=true; TriggerEvent('DTlib:progress:state',true); current=A(); local ok,result=pcall(current.run,current,data); active=false; TriggerEvent('DTlib:progress:state',false); local name=current and current.publicName; current=nil
    if not ok and name~='native' then DT.Debug('Progress provider failed, using native:',result); local n=DT.Modules.Get('progressbar','native'); active=true; TriggerEvent('DTlib:progress:state',true); local ok2,r2=pcall(n.run,n,data); active=false; TriggerEvent('DTlib:progress:state',false); return ok2 and r2==true, ok2 and (r2==true and 'complete' or 'cancelled') or 'failed' end
    return ok and result==true, ok and (result==true and 'complete' or 'cancelled') or 'failed'
end
function DT.ProgressActive() if active then return true end; local a=A(); return a and a.active and a:active() or false end
function DT.ProgressCancel() local a=current or A(); return a and a.cancel and a:cancel() or false end
exports('Progress',function(...) return DT.Progress(...) end); exports('ProgressActive',function(...) return DT.ProgressActive(...) end); exports('CancelProgress',function(...) return DT.ProgressCancel(...) end)
