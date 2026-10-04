exports('GetObject', function() return DT end)
exports('GetVersion', function() return DT.Version end)
exports('GetAdapters', function() return DT.GetAdapters() end)

CreateThread(function()
    Wait(0)
    print(('[DTlib] Client ready | v%s | framework=%s | inventory=%s | target=%s | ui=%s | notify=%s | waypoint=%s | minigames=%s'):format(
        DT.Version,
        DT.Framework.Name(),
        DT.Inventory.Name(),
        DT.Target.Name(),
        DT.UI.Name(),
        DT.NotifyProvider and DT.NotifyProvider() or 'native',
        (DTConfig.Waypoint and DTConfig.Waypoint.enabled) and 'on' or 'off',
        DT.Minigame.Provider()
    ))
end)
