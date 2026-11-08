local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:skill(title, difficulty, inputs, size)
    return exports.lation_ui:skillCheck(title, difficulty, inputs, size)
end
function adapter:skillCancel()
    exports.lation_ui:cancelSkillCheck()
    return true
end
function adapter:skillActive()
    return exports.lation_ui:skillCheckActive() == true
end
function adapter:signal(title, difficulty, inputs, options)
    return exports.lation_ui:signalBreach(title, difficulty, inputs, options)
end
function adapter:signalCancel()
    exports.lation_ui:cancelSignalBreach()
    return true
end
function adapter:signalActive()
    return exports.lation_ui:signalBreachActive() == true
end
function adapter:pattern(title, difficulty)
    return exports.lation_ui:patternLock(title, difficulty)
end
function adapter:patternCancel()
    exports.lation_ui:cancelPatternLock()
    return true
end
function adapter:patternActive()
    return exports.lation_ui:patternLockActive() == true
end
DT.Modules.Register('minigames', 'lation_ui', adapter)
