local function normalise(data,description,notifyType)
    if type(data)=='string' then data={title=data,description=description,type=notifyType} else data=DTUtils.copy(data or {}) end
    local p=DT.NotifyUtil.payload(data,description,notifyType)
    return {id=p.id,title=p.title,message=p.message,type=p.type,duration=p.duration,position=p.position,size=p.size,icon=p.icon,iconColor=p.iconColor,iconAnimation=p.iconAnimation,bgColor=p.bgColor,txtColor=p.txtColor,titleColor=p.titleColor,sound=p.sound,showDuration=p.showDuration,style=p.style,alignIcon=p.alignIcon}
end
function DT.Notify(source,data,description,notifyType) source=tonumber(source); if not source then return false,'invalid_source' end; TriggerClientEvent('DTlib:client:notify',source,normalise(data,description,notifyType)); return true end
function DT.NotifyAll(data,description,notifyType) TriggerClientEvent('DTlib:client:notify',-1,normalise(data,description,notifyType)); return true end
function DT.NotifyPlayers(players,data,description,notifyType) if type(players)~='table' then return false,'invalid_players' end; local p=normalise(data,description,notifyType); for i=1,#players do local s=tonumber(players[i]); if s then TriggerClientEvent('DTlib:client:notify',s,p) end end; return true end

function DT.NotifyProvider()
    local configured = tostring((DTConfig.Adapters and DTConfig.Adapters.notify) or 'auto'):lower()
    local aliases = { lation='lation_ui', lationui='lation_ui', ox='ox_lib', oxlib='ox_lib', okok='okokNotify', okoknotify='okokNotify', dt='native', dtlib='native' }
    configured = aliases[configured] or configured
    if configured ~= 'auto' then
        if configured == 'native' then return 'native' end
        if DTUtils.isStarted(configured) then return configured end
    end
    for _, name in ipairs({'lation_ui','ox_lib','okokNotify'}) do
        if DTUtils.isStarted(name) then return name end
    end
    return 'native'
end

exports('Notify',function(...) return DT.Notify(...) end)
exports('NotifyAll',function(...) return DT.NotifyAll(...) end)
exports('NotifyPlayers',function(...) return DT.NotifyPlayers(...) end)
