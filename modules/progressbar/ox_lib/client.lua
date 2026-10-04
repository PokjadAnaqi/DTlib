local A={resource='ox_lib',publicName='ox_lib'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:run(data)
    local p={duration=math.max(0,tonumber(data.duration) or 1000),label=data.label or 'Processing...',useWhileDead=data.useWhileDead==true,allowRagdoll=data.allowRagdoll==true,allowSwimming=data.allowSwimming==true,allowCuffed=data.allowCuffed==true,allowFalling=data.allowFalling==true,canCancel=data.canCancel~=false,anim=data.anim,prop=data.prop,disable=data.disable}
    local circle=data.circle==true or data.variant=='circle' or data.type=='circle'; if circle then local pos=tostring(data.position or 'middle'):lower(); p.position=(pos=='bottom' or pos=='bottom-center') and 'bottom' or 'middle'; return exports.ox_lib:progressCircle(p) end
    return exports.ox_lib:progressBar(p)
end
function A:active() local ok,v=pcall(function() return exports.ox_lib:progressActive() end); return ok and v==true end
function A:cancel() local ok=pcall(function() exports.ox_lib:cancelProgress() end); return ok end
DT.Modules.Register('progressbar','ox_lib',A)
