local A={resource='native',publicName='native'}
function A:available() return true end
function A:await(data)
    local labels=data.labels or {}
    local result=DT.Input.Await({title=data.header or data.title or 'CONFIRM',description=data.content or data.description,
        fields={},submitText=labels.confirm or 'CONFIRM',cancelText=labels.cancel or 'CANCEL',cancel=data.cancel~=false,provider='native'})
    return result and 'confirm' or 'cancel'
end
function A:close() return DT.Input.Close() end
DT.Modules.Register('alert','native',A)
