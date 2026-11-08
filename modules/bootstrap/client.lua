exports('GetObject', function()
    return DT
end)
exports('GetVersion', function()
    return DT.Version
end)
exports('GetAdapters', function()
    return DT.GetAdapters()
end)

CreateThread(function()
    Wait(0)
    if DTConfig.Console.enabled and DTConfig.Console.startupSummary then
        print(('[DTlib] Client v%s ready | target=%s'):format(DT.Version, DT.Target.Name()))
    end
end)
