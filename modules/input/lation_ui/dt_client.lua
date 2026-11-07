local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
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
    return exports.lation_ui:input({
        title = data.title or 'INPUT',
        subtitle = data.subtitle or data.description,
        submitText = data.submitText,
        cancelText = data.cancelText,
        cancel = data.cancel ~= false,
        type = data.type,
        options = fields(list),
    })
end
function adapter:close()
    exports.lation_ui:closeInput()
    return true
end
DT.Modules.Register('input', 'lation_ui', adapter)
