local A={resource='lation_ui',publicName='lation_ui'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:skill(title,difficulty,inputs,size) return exports.lation_ui:skillCheck(title,difficulty,inputs,size) end
function A:skillCancel() exports.lation_ui:cancelSkillCheck(); return true end
function A:skillActive() return exports.lation_ui:skillCheckActive()==true end
function A:signal(title,difficulty,inputs,options) return exports.lation_ui:signalBreach(title,difficulty,inputs,options) end
function A:signalCancel() exports.lation_ui:cancelSignalBreach(); return true end
function A:signalActive() return exports.lation_ui:signalBreachActive()==true end
function A:pattern(title,difficulty) return exports.lation_ui:patternLock(title,difficulty) end
function A:patternCancel() exports.lation_ui:cancelPatternLock(); return true end
function A:patternActive() return exports.lation_ui:patternLockActive()==true end
DT.Modules.Register('minigames','lation_ui',A)
