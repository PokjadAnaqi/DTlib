-- DTlib bootstrap for DT ecosystem resources.
-- Add `@DTlib/init.lua` to shared_scripts and `dependency 'DTlib'` to fxmanifest.lua.

local resource = GetCurrentResourceName()

if resource == 'DTlib' then
    return
end

local state = GetResourceState('DTlib')
if state ~= 'started' and state ~= 'starting' then
    error(('[DTlib] DTlib must be started before %s. Current state: %s'):format(resource, state), 2)
end

-- Cfx can marshal functions returned inside an export table as callable
-- function-reference tables. They work when invoked, but type(value) becomes
-- "table". A number of DT resources perform capability checks using
-- type(api) == "function", so normalize every Cfx funcref into a local Lua
-- closure before exposing the DT object to the consumer resource.
local function isCfxFunctionRef(value)
    return type(value) == 'table' and rawget(value, '__cfx_functionReference') ~= nil
end

local function wrapCfxFunctionRef(ref)
    return function(...)
        return ref(...)
    end
end

local liveObject
local ready=false
local function liveFunction(path)
    return function(...)
        if not ready then return nil,'dtlib_unavailable' end
        local fn=liveObject
        for _,key in ipairs(path) do fn=type(fn)=='table' and fn[key] or nil end
        if type(fn)~='function' and not isCfxFunctionRef(fn) then return nil,'unsupported_api' end
        return fn(...)
    end
end
local function normalizeFunctionRefs(value, seen, path)
    if isCfxFunctionRef(value) or type(value)=='function' then
        return liveFunction(path or {})
    end

    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local normalized = {}
    seen[value] = normalized

    for key, entry in pairs(value) do
        local entryPath={table.unpack(path or {})};entryPath[#entryPath+1]=key
        normalized[key] = normalizeFunctionRefs(entry, seen, entryPath)
    end

    return normalized
end

local ok, object = pcall(function()
    return exports['DTlib']:GetObject()
end)

if not ok or type(object) ~= 'table' then
    error(('[DTlib] Failed to acquire DT object for %s: %s'):format(resource, tostring(object)), 2)
end

liveObject=object;ready=true
DT = normalizeFunctionRefs(object)
DTlib = DT

-- Placement is intentionally wrapped locally for consumer resources. A
-- placement call can wait for player input for several seconds; keeping the
-- awaiting coroutine in the consumer avoids yielding through a Cfx export
-- function-reference boundary.
if not IsDuplicityVersion() then
    local placementSequence = 0
    local placementPending = {}
    local placementActiveToken = nil

    local function placementCallable(value)
        return type(value) == 'function' or isCfxFunctionRef(value)
    end

    local function placementInvoke(value, ...)
        if not placementCallable(value) then return end
        local fn = isCfxFunctionRef(value) and wrapCfxFunctionRef(value) or value
        local ok, err = pcall(fn, ...)
        if not ok then
            print(('[DTlib] Placement callback failed in %s: %s'):format(resource, tostring(err)))
        end
    end

    local function placementOptions(options)
        if type(options) ~= 'table' then return {} end
        local clean = {}
        for key, value in pairs(options) do
            if key ~= 'onChange' and key ~= 'onConfirm' and key ~= 'onCancel' and key ~= 'onFinish' then
                clean[key] = value
            end
        end
        return clean
    end

    local function newPlacementToken()
        placementSequence = placementSequence + 1
        return ('%s:%s:%s'):format(resource, GetGameTimer(), placementSequence)
    end

    AddEventHandler('DTlib:placement:bridge:change', function(token, result)
        local pending = placementPending[token]
        if not pending then return end
        placementInvoke(pending.options and pending.options.onChange, result)
    end)

    AddEventHandler('DTlib:placement:bridge:response', function(token, result)
        local pending = placementPending[token]
        if not pending then return end
        placementPending[token] = nil
        if placementActiveToken == token then placementActiveToken = nil end
        pending.promise:resolve(result)
    end)

    local function placementRequest(action, payload, options)
        if not ready then return {confirmed=false,cancelled=true,reason='dtlib_unavailable'} end
        local token = newPlacementToken()
        local handle = promise.new()
        placementPending[token] = {
            promise = handle,
            options = options or {}
        }
        placementActiveToken = token
        TriggerEvent('DTlib:placement:bridge:request', token, action, payload)
        local result = Citizen.Await(handle)
        result = type(result) == 'table' and result or {
            confirmed = false,
            cancelled = true,
            reason = 'invalid_result'
        }

        if result.confirmed == true then
            placementInvoke(options and options.onConfirm, result)
        else
            placementInvoke(options and options.onCancel, result)
        end
        placementInvoke(options and options.onFinish, result)
        return result
    end

    AddEventHandler('onClientResourceStop',function(name)
        if name~='DTlib' then return end
        placementActiveToken=nil
        for token,pending in pairs(placementPending) do
            placementPending[token]=nil;pending.promise:resolve({confirmed=false,cancelled=true,reason='dtlib_stopped'})
        end
    end)
    local Placement = {}

    function Placement.Edit(entity, options)
        options = type(options) == 'table' and options or {}
        return placementRequest('edit', {
            entity = entity,
            options = placementOptions(options)
        }, options)
    end

    Placement.Start = Placement.Edit
    Placement.UseGizmo = Placement.Edit

    function Placement.PlaceProp(model, options)
        options = type(options) == 'table' and options or {}
        return placementRequest('prop', {
            model = model,
            options = placementOptions(options)
        }, options)
    end

    Placement.SpawnProp = Placement.PlaceProp

    function Placement.Cancel()
        if not placementActiveToken then return false end
        TriggerEvent('DTlib:placement:bridge:request', placementActiveToken, 'cancel', {})
        return true
    end

    function Placement.Confirm()
        if not placementActiveToken then return false end
        TriggerEvent('DTlib:placement:bridge:request', placementActiveToken, 'confirm', {})
        return true
    end

    function Placement.IsActive()
        return placementActiveToken ~= nil
    end

    function Placement.GetState()
        if not placementActiveToken then return nil end
        return {
            token = placementActiveToken,
            resource = resource
        }
    end

    DT.Placement = Placement
    DT.PropPlacement = Placement

    -- Minigames can remain open while the player interacts with NUI. Keep the
    -- awaiting coroutine in the consumer resource and execute the Lation call
    -- inside DTlib, mirroring the placement bridge strategy.
    local minigameSequence = 0
    local minigamePending = {}
    local minigameActive = {
        skill = nil,
        signal = nil,
        pattern = nil
    }

    local function minigameCallable(value)
        return type(value) == 'function' or isCfxFunctionRef(value)
    end

    local function minigameInvoke(value, ...)
        if not minigameCallable(value) then return end
        local fn = isCfxFunctionRef(value) and wrapCfxFunctionRef(value) or value
        local ok, err = pcall(fn, ...)
        if not ok then
            print(('[DTlib] Minigame callback failed in %s: %s'):format(resource, tostring(err)))
        end
    end

    local function nextMinigameToken(game)
        minigameSequence = minigameSequence + 1
        return ('%s:minigame:%s:%s:%s'):format(resource, game, GetGameTimer(), minigameSequence)
    end

    AddEventHandler('DTlib:minigame:bridge:node', function(token, node, success)
        local pending = minigamePending[token]
        if not pending then return end
        minigameInvoke(pending.onNode, node, success == true)
    end)

    AddEventHandler('DTlib:minigame:bridge:response', function(token, game, success, resultReason)
        local pending = minigamePending[token]
        if not pending then return end
        minigamePending[token] = nil
        if minigameActive[game] == token then minigameActive[game] = nil end
        pending.promise:resolve({
            success = success == true,
            reason = resultReason
        })
    end)

    local function minigameRequest(game, payload, onNode)
        if not ready then return false,'dtlib_unavailable' end
        if minigameActive[game] then return false, 'busy' end

        local token = nextMinigameToken(game)
        local handle = promise.new()
        minigamePending[token] = {
            promise = handle,
            onNode = onNode
        }
        minigameActive[game] = token
        TriggerEvent('DTlib:minigame:bridge:request', token, game, payload or {})

        local result = Citizen.Await(handle)
        if type(result) ~= 'table' then return false, 'invalid_result' end
        return result.success == true, result.reason
    end

    AddEventHandler('onClientResourceStop',function(name)
        if name~='DTlib' then return end
        minigameActive={skill=nil,signal=nil,pattern=nil}
        for token,pending in pairs(minigamePending) do
            minigamePending[token]=nil;pending.promise:resolve({success=false,reason='dtlib_stopped'})
        end
    end)
    local Minigame = {}

    function Minigame.Provider(game)
        local ok, value = pcall(function() return exports['DTlib']:MinigameProvider(game) end)
        return ok and value or 'unavailable'
    end

    function Minigame.Available(game)
        local provider = Minigame.Provider(game)
        return provider ~= 'unavailable' and provider ~= 'disabled'
    end

    function Minigame.SkillCheck(title, difficulty, inputs, size)
        if type(title) == 'table' then
            local data = title
            return minigameRequest('skill', {
                title = data.title or 'Skill Check',
                difficulty = data.difficulty or 'medium',
                inputs = data.inputs or 'E',
                size = data.size or 'normal'
            })
        end
        return minigameRequest('skill', {
            title = title or 'Skill Check',
            difficulty = difficulty or 'medium',
            inputs = inputs or 'E',
            size = size or 'normal'
        })
    end

    function Minigame.CancelSkillCheck()
        TriggerEvent('DTlib:minigame:bridge:cancel', 'skill')
        return true
    end

    function Minigame.SkillCheckActive()
        if minigameActive.skill then return true end
        local ok, value = pcall(function() return exports['DTlib']:SkillCheckActive() end)
        return ok and value == true or false
    end

    function Minigame.SignalBreach(title, difficulty, inputs, options)
        local onNode
        local payload
        if type(title) == 'table' then
            local data = title
            local opts = type(data.options) == 'table' and data.options or {}
            onNode = opts.onNode or data.onNode
            local clean = {}
            for key, value in pairs(opts) do
                if key ~= 'onNode' then clean[key] = value end
            end
            payload = {
                title = data.title or 'Signal Breach',
                difficulty = data.difficulty or 'medium',
                inputs = data.inputs or 'E',
                options = clean,
                emitNode = minigameCallable(onNode)
            }
        else
            options = type(options) == 'table' and options or {}
            onNode = options.onNode
            local clean = {}
            for key, value in pairs(options) do
                if key ~= 'onNode' then clean[key] = value end
            end
            payload = {
                title = title or 'Signal Breach',
                difficulty = difficulty or 'medium',
                inputs = inputs or 'E',
                options = clean,
                emitNode = minigameCallable(onNode)
            }
        end
        return minigameRequest('signal', payload, onNode)
    end

    function Minigame.CancelSignalBreach()
        TriggerEvent('DTlib:minigame:bridge:cancel', 'signal')
        return true
    end

    function Minigame.SignalBreachActive()
        if minigameActive.signal then return true end
        local ok, value = pcall(function() return exports['DTlib']:SignalBreachActive() end)
        return ok and value == true or false
    end

    function Minigame.PatternLock(title, difficulty)
        if type(title) == 'table' then
            local data = title
            return minigameRequest('pattern', {
                title = data.title or 'Pattern Lock',
                difficulty = data.difficulty or 'medium'
            })
        end
        return minigameRequest('pattern', {
            title = title or 'Pattern Lock',
            difficulty = difficulty or 'medium'
        })
    end

    function Minigame.CancelPatternLock()
        TriggerEvent('DTlib:minigame:bridge:cancel', 'pattern')
        return true
    end

    function Minigame.PatternLockActive()
        if minigameActive.pattern then return true end
        local ok, value = pcall(function() return exports['DTlib']:PatternLockActive() end)
        return ok and value == true or false
    end

    Minigame.skillCheck = Minigame.SkillCheck
    Minigame.cancelSkillCheck = Minigame.CancelSkillCheck
    Minigame.skillCheckActive = Minigame.SkillCheckActive
    Minigame.signalBreach = Minigame.SignalBreach
    Minigame.cancelSignalBreach = Minigame.CancelSignalBreach
    Minigame.signalBreachActive = Minigame.SignalBreachActive
    Minigame.patternLock = Minigame.PatternLock
    Minigame.cancelPatternLock = Minigame.CancelPatternLock
    Minigame.patternLockActive = Minigame.PatternLockActive

    DT.Minigame = Minigame
    DT.SkillCheck = Minigame.SkillCheck
    DT.SignalBreach = Minigame.SignalBreach
    DT.PatternLock = Minigame.PatternLock
    DT.UI = DT.UI or {}
    DT.UI.SkillCheck = Minigame.SkillCheck
    DT.UI.SignalBreach = Minigame.SignalBreach
    DT.UI.PatternLock = Minigame.PatternLock
end

-- Awaiting UI stays in the consuming resource's coroutine, like placement/minigames.
if not IsDuplicityVersion() then
    local pending,sequence={},0
    AddEventHandler('DTlib:ui:bridge:response',function(token,result)
        local waiter=pending[token];if not waiter then return end
        pending[token]=nil;waiter:resolve(result)
    end)
    local function uiRequest(action,data)
        if not ready then return nil,'dtlib_unavailable' end
        sequence=sequence+1
        local token=('%s:%s:ui:%s'):format(resource,GetGameTimer(),sequence)
        local waiter=promise.new();pending[token]=waiter
        TriggerEvent('DTlib:ui:bridge:request',token,action,data)
        local result=Citizen.Await(waiter)
        return table.unpack(result,1,result.n or 2)
    end
    DT.Progress=function(data) return uiRequest('progress',data) end
    DT.Input.Await=function(data) return uiRequest('input',data) end
    DT.Alert.Await=function(data) return uiRequest('alert',data) end
    DT.Alert.Show=DT.Alert.Await;DT.UI.Alert=DT.Alert.Await
    AddEventHandler('onClientResourceStop',function(name)
        if name~='DTlib' then return end
        for token,waiter in pairs(pending) do pending[token]=nil;waiter:resolve({n=2,[2]='dtlib_stopped'}) end
    end)
end

-- Stable local function wrappers rebind to the new DTlib object after a restart.
function DT.IsReady() return ready end
function DT.AwaitReady(timeoutMs)
    timeoutMs=tonumber(timeoutMs) or 10000
    if timeoutMs~=timeoutMs or timeoutMs<0 or timeoutMs==math.huge then return false,'invalid_timeout' end
    local deadline=GetGameTimer()+math.min(timeoutMs,60000)
    while not ready do
        if GetGameTimer()>=deadline then return false,'dtlib_timeout' end
        Wait(50)
    end
    return true
end
local resourceStart=IsDuplicityVersion() and 'onResourceStart' or 'onClientResourceStart'
local resourceStop=IsDuplicityVersion() and 'onResourceStop' or 'onClientResourceStop'
local generation=0
AddEventHandler(resourceStop,function(name)
    if name=='DTlib' then generation=generation+1;ready=false;liveObject=nil end
end)
AddEventHandler(resourceStart,function(name)
    if name~='DTlib' then return end
    generation=generation+1;local current=generation
    CreateThread(function()
        for attempt=1,100 do
            if current~=generation then return end
            local success,fresh=pcall(function() return exports.DTlib:GetObject() end)
            if success and type(fresh)=='table' then
                liveObject=fresh;ready=true;DT.Version=fresh.Version
                TriggerEvent('DTlib:consumer:ready',resource,DT.Version)
                return
            end
            Wait(100)
        end
    end)
end)
if not IsDuplicityVersion() then
    local tools={}
    DT.Admin=DT.Admin or {}
    function DT.Admin.RegisterTool(data)
        local success,err=exports.DTlib:RegisterAdminTool(data)
        if success then tools[data.id]=data end
        return success,err
    end
    function DT.Admin.UnregisterTool(id)
        tools[id]=nil
        if not ready then return true end
        return exports.DTlib:UnregisterAdminTool(id)
    end
    AddEventHandler('DTlib:admin:ready',function()
        for _,data in pairs(tools) do exports.DTlib:RegisterAdminTool(data) end
    end)
end
