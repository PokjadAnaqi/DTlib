local activeProvider
local function A() return DT.UI.Adapter('alert') end
function DT.Alert.Await(data)
    if activeProvider then return nil,'busy' end
    data=type(data)=='table' and data or {content=tostring(data or '')}
    local a=A(); activeProvider=a
    local ok,result=pcall(a.await,a,data); activeProvider=nil
    if ok then return result end
    DT.Debug('Alert provider failed:',result)
    if a.publicName~='native' then return DT.Modules.Get('alert','native'):await(data) end
    return nil,tostring(result)
end
function DT.Alert.Close() local a=activeProvider or A(); return a and a.close and a:close() or false end
DT.Alert.Show=DT.Alert.Await; DT.UI.Alert=DT.Alert.Await
exports('Alert',function(...) return DT.Alert.Await(...) end)
exports('CloseAlert',function(...) return DT.Alert.Close(...) end)
