local active={skill=false,signal=false,pattern=false}
local warned={}
local function adapter(game)
    local name=DT.Minigame.Provider(game)
    local a=DT.Modules.Get('minigames',name)
    if a then warned[game]=nil; return a end
    if not warned[game] then warned[game]=true; DT.Debug(('Minigame %s unavailable (provider=%s)'):format(tostring(game),tostring(name))) end
end
local function result(v,e) if v==true then return true,'complete' end; return false,e and tostring(e) or 'failed' end
local function skillArgs(title,difficulty,inputs,size) if type(title)=='table' then local d=title; return d.title or 'Skill Check',d.difficulty or 'medium',d.inputs or 'E',d.size or 'normal' end; return title or 'Skill Check',difficulty or 'medium',inputs or 'E',size or 'normal' end
local function signalArgs(title,difficulty,inputs,options) if type(title)=='table' then local d=title; return d.title or 'Signal Breach',d.difficulty or 'medium',d.inputs or 'E',d.options or {} end; return title or 'Signal Breach',difficulty or 'medium',inputs or 'E',options or {} end
local function patternArgs(title,difficulty) if type(title)=='table' then local d=title; return d.title or 'Pattern Lock',d.difficulty or 'medium' end; return title or 'Pattern Lock',difficulty or 'medium' end
function DT.Minigame.SkillCheck(title,difficulty,inputs,size)
    local a=adapter('skill'); if not a or not a.skill then return false,'unavailable' end; if active.skill then return false,'busy' end
    title,difficulty,inputs,size=skillArgs(title,difficulty,inputs,size); active.skill=true; local ok,v=pcall(a.skill,a,title,difficulty,inputs,size); active.skill=false; if not ok then return false,tostring(v) end; return result(v)
end
function DT.Minigame.CancelSkillCheck() local a=adapter('skill'); return a and a.skillCancel and pcall(a.skillCancel,a) or false end
function DT.Minigame.SkillCheckActive() if active.skill then return true end; local a=adapter('skill'); if not a or not a.skillActive then return false end; local ok,v=pcall(a.skillActive,a); return ok and v==true end
function DT.Minigame.SignalBreach(title,difficulty,inputs,options)
    local a=adapter('signal'); if not a or not a.signal then return false,'unavailable' end; if active.signal then return false,'busy' end
    title,difficulty,inputs,options=signalArgs(title,difficulty,inputs,options); if type(options)=='table' and DTUtils.isCallable(options.onNode) then options=DTUtils.copy(options); options.onNode=DTUtils.wrapCallable(options.onNode) end
    active.signal=true; local ok,v=pcall(a.signal,a,title,difficulty,inputs,options); active.signal=false; if not ok then return false,tostring(v) end; return result(v)
end
function DT.Minigame.CancelSignalBreach() local a=adapter('signal'); if not a or not a.signalCancel then return false end; local ok=pcall(a.signalCancel,a); return ok end
function DT.Minigame.SignalBreachActive() if active.signal then return true end; local a=adapter('signal'); if not a or not a.signalActive then return false end; local ok,v=pcall(a.signalActive,a); return ok and v==true end
function DT.Minigame.PatternLock(title,difficulty)
    local a=adapter('pattern'); if not a or not a.pattern then return false,'unavailable' end; if active.pattern then return false,'busy' end
    title,difficulty=patternArgs(title,difficulty); active.pattern=true; local ok,v=pcall(a.pattern,a,title,difficulty); active.pattern=false; if not ok then return false,tostring(v) end; return result(v)
end
function DT.Minigame.CancelPatternLock() local a=adapter('pattern'); if not a or not a.patternCancel then return false end; local ok=pcall(a.patternCancel,a); return ok end
function DT.Minigame.PatternLockActive() if active.pattern then return true end; local a=adapter('pattern'); if not a or not a.patternActive then return false end; local ok,v=pcall(a.patternActive,a); return ok and v==true end
DT.Minigame.skillCheck=DT.Minigame.SkillCheck; DT.Minigame.cancelSkillCheck=DT.Minigame.CancelSkillCheck; DT.Minigame.skillCheckActive=DT.Minigame.SkillCheckActive; DT.Minigame.signalBreach=DT.Minigame.SignalBreach; DT.Minigame.cancelSignalBreach=DT.Minigame.CancelSignalBreach; DT.Minigame.signalBreachActive=DT.Minigame.SignalBreachActive; DT.Minigame.patternLock=DT.Minigame.PatternLock; DT.Minigame.cancelPatternLock=DT.Minigame.CancelPatternLock; DT.Minigame.patternLockActive=DT.Minigame.PatternLockActive
DT.SkillCheck=DT.Minigame.SkillCheck; DT.SignalBreach=DT.Minigame.SignalBreach; DT.PatternLock=DT.Minigame.PatternLock; DT.UI.SkillCheck=DT.Minigame.SkillCheck; DT.UI.SignalBreach=DT.Minigame.SignalBreach; DT.UI.PatternLock=DT.Minigame.PatternLock
local function bridgeRun(token,game,payload)
    CreateThread(function() local success,reason; if game=='skill' then success,reason=DT.Minigame.SkillCheck(payload.title,payload.difficulty,payload.inputs,payload.size) elseif game=='signal' then local options=payload.options or {}; if payload.emitNode==true then options.onNode=function(node,nodeSuccess) TriggerEvent('DTlib:minigame:bridge:node',token,node,nodeSuccess==true) end end; success,reason=DT.Minigame.SignalBreach(payload.title,payload.difficulty,payload.inputs,options) elseif game=='pattern' then success,reason=DT.Minigame.PatternLock(payload.title,payload.difficulty) else success,reason=false,'unknown_minigame' end; TriggerEvent('DTlib:minigame:bridge:response',token,game,success==true,reason) end)
end
AddEventHandler('DTlib:minigame:bridge:request',function(token,game,payload) bridgeRun(token,game,type(payload)=='table' and payload or {}) end)
AddEventHandler('DTlib:minigame:bridge:cancel',function(game) if game=='skill' then DT.Minigame.CancelSkillCheck() elseif game=='signal' then DT.Minigame.CancelSignalBreach() elseif game=='pattern' then DT.Minigame.CancelPatternLock() end end)
exports('SkillCheck',function(...) return DT.Minigame.SkillCheck(...) end); exports('CancelSkillCheck',function() return DT.Minigame.CancelSkillCheck() end); exports('SkillCheckActive',function() return DT.Minigame.SkillCheckActive() end); exports('SignalBreach',function(...) return DT.Minigame.SignalBreach(...) end); exports('CancelSignalBreach',function() return DT.Minigame.CancelSignalBreach() end); exports('SignalBreachActive',function() return DT.Minigame.SignalBreachActive() end); exports('PatternLock',function(...) return DT.Minigame.PatternLock(...) end); exports('CancelPatternLock',function() return DT.Minigame.CancelPatternLock() end); exports('PatternLockActive',function() return DT.Minigame.PatternLockActive() end); exports('MinigameProvider',function(game) return DT.Minigame.Provider(game) end); exports('MinigameAvailable',function(game) return DT.Minigame.Available(game) end)
