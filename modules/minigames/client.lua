local active = { skill = false, signal = false, pattern = false }
local warned = {}
local function adapter(game)
    local name = DT.Minigame.Provider(game)
    local provider = DT.Modules.Get('minigames', name)
    if provider then
        warned[game] = nil
        return provider
    end
    if not warned[game] then
        warned[game] = true
        DT.Debug(('Minigame %s unavailable (provider=%s)'):format(tostring(game), tostring(name)))
    end
end
local function result(value, entry)
    if value == true then
        return true, 'complete'
    end
    return false, entry and tostring(entry) or 'failed'
end
local function skillArgs(title, difficulty, inputs, size)
    if type(title) == 'table' then
        local data = title
        return data.title or 'Skill Check', data.difficulty or 'medium', data.inputs or 'E', data.size or 'normal'
    end
    return title or 'Skill Check', difficulty or 'medium', inputs or 'E', size or 'normal'
end
local function signalArgs(title, difficulty, inputs, options)
    if type(title) == 'table' then
        local data = title
        return data.title or 'Signal Breach', data.difficulty or 'medium', data.inputs or 'E', data.options or {}
    end
    return title or 'Signal Breach', difficulty or 'medium', inputs or 'E', options or {}
end
local function patternArgs(title, difficulty)
    if type(title) == 'table' then
        local data = title
        return data.title or 'Pattern Lock', data.difficulty or 'medium'
    end
    return title or 'Pattern Lock', difficulty or 'medium'
end
function DT.Minigame.SkillCheck(title, difficulty, inputs, size)
    local provider = adapter('skill')
    if not provider or not provider.skill then
        return false, 'unavailable'
    end
    if active.skill then
        return false, 'busy'
    end
    title, difficulty, inputs, size = skillArgs(title, difficulty, inputs, size)
    active.skill = true
    local ok, value = pcall(provider.skill, provider, title, difficulty, inputs, size)
    active.skill = false
    if not ok then
        return false, tostring(value)
    end
    return result(value)
end
function DT.Minigame.CancelSkillCheck()
    local provider = adapter('skill')
    return provider and provider.skillCancel and pcall(provider.skillCancel, provider) or false
end
function DT.Minigame.SkillCheckActive()
    if active.skill then
        return true
    end
    local provider = adapter('skill')
    if not provider or not provider.skillActive then
        return false
    end
    local ok, value = pcall(provider.skillActive, provider)
    return ok and value == true
end
function DT.Minigame.SignalBreach(title, difficulty, inputs, options)
    local provider = adapter('signal')
    if not provider or not provider.signal then
        return false, 'unavailable'
    end
    if active.signal then
        return false, 'busy'
    end
    title, difficulty, inputs, options = signalArgs(title, difficulty, inputs, options)
    if type(options) == 'table' and DTUtils.isCallable(options.onNode) then
        options = DTUtils.copy(options)
        options.onNode = DTUtils.wrapCallable(options.onNode)
    end
    active.signal = true
    local ok, value = pcall(provider.signal, provider, title, difficulty, inputs, options)
    active.signal = false
    if not ok then
        return false, tostring(value)
    end
    return result(value)
end
function DT.Minigame.CancelSignalBreach()
    local provider = adapter('signal')
    if not provider or not provider.signalCancel then
        return false
    end
    local ok = pcall(provider.signalCancel, provider)
    return ok
end
function DT.Minigame.SignalBreachActive()
    if active.signal then
        return true
    end
    local provider = adapter('signal')
    if not provider or not provider.signalActive then
        return false
    end
    local ok, value = pcall(provider.signalActive, provider)
    return ok and value == true
end
function DT.Minigame.PatternLock(title, difficulty)
    local provider = adapter('pattern')
    if not provider or not provider.pattern then
        return false, 'unavailable'
    end
    if active.pattern then
        return false, 'busy'
    end
    title, difficulty = patternArgs(title, difficulty)
    active.pattern = true
    local ok, value = pcall(provider.pattern, provider, title, difficulty)
    active.pattern = false
    if not ok then
        return false, tostring(value)
    end
    return result(value)
end
function DT.Minigame.CancelPatternLock()
    local provider = adapter('pattern')
    if not provider or not provider.patternCancel then
        return false
    end
    local ok = pcall(provider.patternCancel, provider)
    return ok
end
function DT.Minigame.PatternLockActive()
    if active.pattern then
        return true
    end
    local provider = adapter('pattern')
    if not provider or not provider.patternActive then
        return false
    end
    local ok, value = pcall(provider.patternActive, provider)
    return ok and value == true
end
DT.Minigame.skillCheck = DT.Minigame.SkillCheck
DT.Minigame.cancelSkillCheck = DT.Minigame.CancelSkillCheck
DT.Minigame.skillCheckActive = DT.Minigame.SkillCheckActive
DT.Minigame.signalBreach = DT.Minigame.SignalBreach
DT.Minigame.cancelSignalBreach = DT.Minigame.CancelSignalBreach
DT.Minigame.signalBreachActive = DT.Minigame.SignalBreachActive
DT.Minigame.patternLock = DT.Minigame.PatternLock
DT.Minigame.cancelPatternLock = DT.Minigame.CancelPatternLock
DT.Minigame.patternLockActive = DT.Minigame.PatternLockActive
DT.SkillCheck = DT.Minigame.SkillCheck
DT.SignalBreach = DT.Minigame.SignalBreach
DT.PatternLock = DT.Minigame.PatternLock
DT.UI.SkillCheck = DT.Minigame.SkillCheck
DT.UI.SignalBreach = DT.Minigame.SignalBreach
DT.UI.PatternLock = DT.Minigame.PatternLock
local function bridgeRun(token, game, payload)
    CreateThread(function()
        local success, reason
        if game == 'skill' then
            success, reason = DT.Minigame.SkillCheck(payload.title, payload.difficulty, payload.inputs, payload.size)
        elseif game == 'signal' then
            local options = payload.options or {}
            if payload.emitNode == true then
                options.onNode = function(node, nodeSuccess)
                    TriggerEvent('DTlib:minigame:bridge:node', token, node, nodeSuccess == true)
                end
            end
            success, reason = DT.Minigame.SignalBreach(payload.title, payload.difficulty, payload.inputs, options)
        elseif game == 'pattern' then
            success, reason = DT.Minigame.PatternLock(payload.title, payload.difficulty)
        else
            success, reason = false, 'unknown_minigame'
        end
        TriggerEvent('DTlib:minigame:bridge:response', token, game, success == true, reason)
    end)
end
AddEventHandler('DTlib:minigame:bridge:request', function(token, game, payload)
    bridgeRun(token, game, type(payload) == 'table' and payload or {})
end)
AddEventHandler('DTlib:minigame:bridge:cancel', function(game)
    if game == 'skill' then
        DT.Minigame.CancelSkillCheck()
    elseif game == 'signal' then
        DT.Minigame.CancelSignalBreach()
    elseif game == 'pattern' then
        DT.Minigame.CancelPatternLock()
    end
end)
exports('SkillCheck', function(...)
    return DT.Minigame.SkillCheck(...)
end)
exports('CancelSkillCheck', function()
    return DT.Minigame.CancelSkillCheck()
end)
exports('SkillCheckActive', function()
    return DT.Minigame.SkillCheckActive()
end)
exports('SignalBreach', function(...)
    return DT.Minigame.SignalBreach(...)
end)
exports('CancelSignalBreach', function()
    return DT.Minigame.CancelSignalBreach()
end)
exports('SignalBreachActive', function()
    return DT.Minigame.SignalBreachActive()
end)
exports('PatternLock', function(...)
    return DT.Minigame.PatternLock(...)
end)
exports('CancelPatternLock', function()
    return DT.Minigame.CancelPatternLock()
end)
exports('PatternLockActive', function()
    return DT.Minigame.PatternLockActive()
end)
exports('MinigameProvider', function(game)
    return DT.Minigame.Provider(game)
end)
exports('MinigameAvailable', function(game)
    return DT.Minigame.Available(game)
end)
