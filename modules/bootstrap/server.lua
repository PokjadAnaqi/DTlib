exports('GetObject', function() return DT end)
exports('GetVersion', function() return DT.Version end)
exports('GetAdapters', function() return DT.GetAdapters() end)
exports('GetRuntimeStatus', function()
    return DT.Logger.GetRuntimeStatus and DT.Logger.GetRuntimeStatus() or DT.GetAdapters()
end)
exports('PrintStatus', function(reason)
    if DT.Logger.PrintStatus then DT.Logger.PrintStatus(reason or 'export') end
end)

CreateThread(function()
    Wait(250)
    DT.Logger.Info('BOOT', ('Server runtime ready | v%s'):format(DT.Version))
    if DTConfig.Console.startupSummary then DT.Logger.PrintStatus('resource start') end
end)
