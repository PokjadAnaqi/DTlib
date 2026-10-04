local A={resource='lation_ui',publicName='lation_ui'}
local function fields(list)
    local out={}; for i=1,#(list or {}) do local f=DTUtils.copy(list[i]); local t=f.type; if not t or t=='text' then t='input' end; f.type=t; f.name=nil; out[i]=f end; return out
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:await(data,list) return exports.lation_ui:input({title=data.title or 'INPUT',subtitle=data.subtitle or data.description,submitText=data.submitText,cancelText=data.cancelText,cancel=data.cancel~=false,type=data.type,options=fields(list)}) end
function A:close() exports.lation_ui:closeInput(); return true end
DT.Modules.Register('input','lation_ui',A)
