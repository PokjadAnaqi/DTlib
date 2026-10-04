local A={resource='ox_lib',publicName='ox_lib'}
local function inputs(value)
    if value==nil then return nil end
    if type(value)=='string' then return {value:lower()} end
    if type(value)~='table' then return nil end
    local out={}; for i=1,#value do if type(value[i])=='string' then out[#out+1]=value[i]:lower() end end; return #out>0 and out or nil
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:skill(_,difficulty,value) return exports.ox_lib:skillCheck(difficulty,inputs(value)) end
function A:skillCancel() exports.ox_lib:cancelSkillCheck(); return true end
function A:skillActive() return exports.ox_lib:skillCheckActive()==true end
DT.Modules.Register('minigames','ox_lib',A)
