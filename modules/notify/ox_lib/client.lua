local A={resource='ox_lib',publicName='ox_lib'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:send(p)
    exports.ox_lib:notify({id=p.id,title=p.title,description=p.message,type=p.type=='info' and 'inform' or p.type,duration=p.duration,position=p.position,showDuration=p.showDuration,style=p.style,icon=p.icon,iconColor=p.iconColor,iconAnimation=p.iconAnimation,alignIcon=p.alignIcon,sound=p.sound}); return true
end
DT.Modules.Register('notify','ox_lib',A)
