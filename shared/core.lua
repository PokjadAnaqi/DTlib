DT = DT or {}
DT.Version = '1.3.0-beta.11'
DT.Config = DTConfig
DT.Utils = DTUtils

DT.Resource = DT.Resource or {}
DT.State = DT.State or {}
DT.Routing = DT.Routing or {}
DT.Entity = DT.Entity or {}
DT.Ace = DT.Ace or {}
DT.OneSync = DT.OneSync or {}
DT.Framework = DT.Framework or {}
DT.Player = DT.Player or {}
DT.Inventory = DT.Inventory or {}
DT.Callback = DT.Callback or {}
DT.UI = DT.UI or {}
DT.Notify = DT.Notify or function() end
DT.NotifyAll = DT.NotifyAll or function() end
DT.NotifyPlayers = DT.NotifyPlayers or function() end
DT.Progress = DT.Progress or function() return false end
DT.TextUI = DT.TextUI or {}
DT.Menu = DT.Menu or {}
DT.Input = DT.Input or {}
DT.Alert = DT.Alert or {}
DT.Minigame = DT.Minigame or {}
DT.Zone = DT.Zone or {}
DT.Placement = DT.Placement or {}
DT.PropPlacement = DT.Placement
DT.Waypoint = DT.Waypoint or {}
DT.Target = DT.Target or {}
DT.Database = DT.Database or {}
DT.Discord = DT.Discord or {}
DT.Security = DT.Security or {}
DT.Logger = DT.Logger or {}
DT.Vehicle = DT.Vehicle or {}
DT.Weather = DT.Weather or {}

function DT.Resource.State(resource)
    return GetResourceState(resource)
end

function DT.Resource.Started(resource)
    return DTUtils.isStarted(resource)
end

function DT.Resource.Detect(preferred, candidates)
    return DTUtils.detect(preferred, candidates)
end

function DT.Resource.Current()
    return GetCurrentResourceName()
end

function DT.Resource.Version(resource)
    resource = resource or GetCurrentResourceName()
    return GetResourceMetadata(resource, 'version', 0)
end

function DT.Resource.Metadata(resource, key, index)
    if key == nil then
        key, resource = resource, GetCurrentResourceName()
    end
    return GetResourceMetadata(resource, key, index or 0)
end

function DT.UI.Name()
    local configured = DTConfig.Adapters.ui or 'auto'
    if configured == 'lation' or configured == 'lationui' then configured = 'lation_ui' end
    if configured == 'ox' or configured == 'oxlib' then configured = 'ox_lib' end
    if configured == 'dt' or configured == 'native' or configured == 'dtlib' then return 'native' end
    return DTUtils.detect(configured, {'lation_ui', 'ox_lib'}) or 'native'
end

function DT.UI.UsingLation()
    return DT.UI.Name() == 'lation_ui'
end

function DT.UI.UsingOxLib()
    return DT.UI.Name() == 'ox_lib'
end


function DT.Minigame.Provider(game)
    local config = DTConfig.Minigames or {}
    if config.enabled == false then return 'disabled' end

    local provider = tostring(config.provider or 'auto'):lower()
    if provider == 'lation' or provider == 'lationui' then provider = 'lation_ui' end
    if provider == 'ox' or provider == 'oxlib' then provider = 'ox_lib' end
    if provider == 'none' or provider == 'disabled' or provider == 'off' then return 'disabled' end

    game = game and tostring(game):lower() or nil
    local skillGame = game == nil or game == 'skill' or game == 'skillcheck' or game == 'skill_check'

    if (provider == 'auto' or provider == 'lation_ui') and DTUtils.isStarted('lation_ui') then
        return 'lation_ui'
    end

    if skillGame and (provider == 'auto' or provider == 'ox_lib') and DTUtils.isStarted('ox_lib') then
        return 'ox_lib'
    end

    return 'unavailable'
end

function DT.Minigame.Available(game)
    local provider = DT.Minigame.Provider(game)
    return provider ~= 'unavailable' and provider ~= 'disabled'
end

function DT.GetVersion()
    return DT.Version
end

local function placementAdapterName()
    if DT.Placement and DT.Placement.Provider then
        local ok, value = pcall(DT.Placement.Provider)
        if ok and value then return value end
    end

    local configured = DTConfig.Placement and tostring(DTConfig.Placement.provider or 'native'):lower() or 'native'
    if configured == 'native' or configured == 'dtlib' or configured == 'dtlib_gizmo' or configured == 'legacy' or configured == 'v1.0.6' then
        return 'dtlib_gizmo'
    end

    if configured == 'auto' or configured == 'object_gizmo' or configured == 'object' or configured == 'external' then
        if DTUtils.isStarted('object_gizmo') then
            local version = GetResourceMetadata('object_gizmo', 'version', 0) or ''
            local major = tonumber(tostring(version):match('(%d+)')) or 0
            local required = DTConfig.Placement and DTConfig.Placement.objectGizmoMajor or 3
            if major >= required then return ('object_gizmo@%s'):format(version ~= '' and version or 'v3+') end
        end
    end

    return 'dtlib_gizmo'
end

function DT.GetAdapters()
    return {
        framework = DT.Framework.Name and DT.Framework.Name() or 'none',
        inventory = DT.Inventory.Name and DT.Inventory.Name() or 'none',
        target = DT.Target.Name and DT.Target.Name() or 'none',
        database = DT.Database.Name and DT.Database.Name() or 'none',
        weather = DT.Weather.Name and DT.Weather.Name() or 'native',
        ui = DT.UI.Name(),
        notify = DT.NotifyProvider and DT.NotifyProvider() or 'native',
        placement = placementAdapterName(),
        waypoint = (DTConfig.Waypoint and DTConfig.Waypoint.enabled) and 'dtlib_waypoint' or 'disabled',
        minigames = DT.Minigame.Provider(),
        alert = DT.UI.Adapter and DT.UI.Adapter('alert').publicName or 'native',
        listmenu = DT.ListMenu and DT.ListMenu.Provider() or 'unavailable',
        banking = DT.Ecosystem and DT.Ecosystem.Provider('banking') or 'unavailable',
        fuel = DT.Ecosystem and DT.Ecosystem.Provider('fuel') or 'unavailable',
        vehiclekey = DT.Ecosystem and DT.Ecosystem.Provider('vehiclekey') or 'unavailable',
        phone = DT.Ecosystem and DT.Ecosystem.Provider('phone') or 'unavailable'
    }
end

function DT.Debug(...)
    if not DTConfig.Debug then return end
    local args = {...}
    local output = {}
    for i = 1, #args do output[i] = tostring(args[i]) end
    if DT.Logger and DT.Logger.Debug then
        DT.Logger.Debug('DEBUG', table.concat(output, ' '))
    else
        print(('[DTlib:DEBUG] %s'):format(table.concat(output, ' ')))
    end
end
