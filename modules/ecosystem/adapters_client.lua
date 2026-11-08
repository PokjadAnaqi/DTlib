-- Adapt provider signatures to DTlib's existing UI contracts.
local ecosystem = DT.Ecosystem
local function reg(category, provider, adapter)
    if provider.default or DT.Modules.Get(category, provider.resource) then
        return
    end
    adapter.resource = provider.resource
    adapter.publicName = provider.resource
    function adapter:available()
        return DTConfig.Ecosystem.enabled ~= false and DTUtils.isStarted(self.resource)
    end
    DT.Modules.Register(category, provider.resource, adapter)
end
for _, provider in ipairs(DTEcosystemCatalog.notify.providers) do
    local name = provider.name
    reg('notify', provider, {
        send = function(_, data)
            local left, errorMessage = ecosystem.Get('notify', name)
            if not left then
                error(errorMessage)
            end
            left.SendNotification(data.title, data.message or data.description, data.type, data.duration, data)
            return true
        end,
    })
end
for _, provider in ipairs(DTEcosystemCatalog.helptext.providers) do
    local name = provider.name
    local shown = false
    local text
    reg('helptext', provider, {
        show = function(_, data)
            local left, errorMessage = ecosystem.Get('helptext', name)
            if not left then
                error(errorMessage)
            end
            text = data.description or data.text or ''
            left.ShowHelpText(text, data.position)
            shown = true
            return true
        end,
        hide = function()
            local left, errorMessage = ecosystem.Get('helptext', name)
            if not left then
                error(errorMessage)
            end
            left.HideHelpText()
            shown = false
            text = nil
            return true
        end,
        isOpen = function()
            return shown, text
        end,
    })
end
for _, provider in ipairs(DTEcosystemCatalog.progressbar.providers) do
    local name = provider.name
    reg('progressbar', provider, {
        run = function(_, data)
            local left, errorMessage = ecosystem.Get('progressbar', name)
            if not left then
                error(errorMessage)
            end
            return left.Open(data, nil, false)
        end,
    })
end
for _, provider in ipairs(DTEcosystemCatalog.input.providers) do
    local name = provider.name
    reg('input', provider, {
        await = function(_, data, fields)
            local left, errorMessage = ecosystem.Get('input', name)
            if not left then
                error(errorMessage)
            end
            return left.Open(data.title or 'INPUT', fields, false, data.submitText)
        end,
        close = function()
            return false, 'unsupported_backend'
        end,
    })
end
for _, provider in ipairs(DTEcosystemCatalog.menu.providers) do
    local name = provider.name
    reg('menu', provider, {
        open = function(_, id, data, items, select, onExit)
            local left, errorMessage = ecosystem.Get('menu', name)
            if not left then
                error(errorMessage)
            end
            local options = {}
            for entryKey, item in ipairs(items) do
                local index = entryKey
                options[entryKey] = DTUtils.copy(item)
                options[entryKey].title = item.title or item.label
                options[entryKey].onSelect = function()
                    select(index)
                end
            end
            left.Open(
                {
                    id = id,
                    title = data.title or 'MENU',
                    options = options,
                    onExit = onExit,
                    canClose = data.canClose,
                    position = data.position,
                },
                false
            )
            return id
        end,
        close = function(self)
            if self.resource == 'qb-menu' then
                exports['qb-menu']:closeMenu()
                return true
            end
            if self.resource == 'wasabi_uikit' then
                exports.wasabi_uikit:hideContext(false)
                return true
            end
            return false, 'unsupported_backend'
        end,
    })
end
local aliases = {
    lation = 'lation_ui',
    lationui = 'lation_ui',
    ox = 'ox_lib',
    oxlib = 'ox_lib',
    okoktextui = 'okokTextUI',
    okok = 'okokTextUI',
    dt = 'native',
    dtlib = 'native',
    ['qb-progressbar'] = 'progressbar',
    zsxui = 'ZSX_UIV2',
}
function DT.UI.Adapter(category, override)
    local key = ({ helptext = 'textui', progressbar = 'progress' })[category] or category
    local configured = override or DTConfig.Adapters[key]
    if not configured or configured == 'auto' then
        configured = DTConfig.Adapters.ui or 'auto'
    end
    if configured == 'disabled' or configured == 'none' then
        configured = 'native'
    end
    local candidates = {}
    for _, entryKey in ipairs({ 'lation_ui', 'ox_lib', 'okokTextUI' }) do
        if DT.Modules.Get(category, entryKey) then
            candidates[#candidates + 1] = entryKey
        end
    end
    local categoryCatalog = DTEcosystemCatalog[category]
    if categoryCatalog then
        for _, provider in ipairs(categoryCatalog.providers) do
            if not provider.default and not DTUtils.tableContains(candidates, provider.resource) then
                candidates[#candidates + 1] = provider.resource
            end
        end
    end
    return DT.Modules.Resolve(category, configured, candidates, aliases, 'native')
end
