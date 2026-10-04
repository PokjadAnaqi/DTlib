local A={resource='ox_lib',publicName='ox_lib'}
local function fields(list)
    local out={}; for i=1,#(list or {}) do local f=DTUtils.copy(list[i]); local t=f.type; if not t or t=='text' then t='input' end; f.type=t; f.name=nil; out[i]=f end; return out
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:await(data,list) return exports.ox_lib:inputDialog(data.title or 'INPUT',fields(list),{allowCancel=data.cancel~=false,size=data.size}) end
function A:close() exports.ox_lib:closeInputDialog(); return true end
DT.Modules.Register('input','ox_lib',A)
