local adapter = { resource = 'ox_lib', publicName = 'ox_lib' }
local function fields(list)
    local out = {}
    for index = 1, #(list or {}) do
        local handler = DTUtils.copy(list[index])
        local fieldType = handler.type
        if not fieldType or fieldType == 'text' then
            fieldType = 'input'
        end
        handler.type = fieldType
        handler.name = nil
        out[index] = handler
    end
    return out
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:await(data, list)
    return exports.ox_lib:inputDialog(
        data.title or 'INPUT',
        fields(list),
        { allowCancel = data.cancel ~= false, size = data.size }
    )
end
function adapter:close()
    exports.ox_lib:closeInputDialog()
    return true
end
DT.Modules.Register('input', 'ox_lib', adapter)
