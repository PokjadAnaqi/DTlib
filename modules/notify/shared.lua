DT.NotifyUtil = DT.NotifyUtil or {}
local N = DT.NotifyUtil
N.validTypes = {info=true,success=true,warning=true,error=true}
N.validPositions = {['top-left']=true,top=true,['top-center']=true,['top-right']=true,['center-left']=true,['center-right']=true,['bottom-left']=true,bottom=true,['bottom-center']=true,['bottom-right']=true}
N.validSizes = {sm=true,md=true,lg=true}

function N.type(value)
    value=tostring(value or 'info'):lower()
    if value=='inform' or value=='primary' or value=='default' then value='info' end
    if value=='danger' or value=='fail' or value=='failed' then value='error' end
    if value=='warn' then value='warning' end
    return N.validTypes[value] and value or 'info'
end
function N.position(value)
    value=tostring(value or DTConfig.UI.notifyPosition or 'top-right'):lower()
    local aliases={topleft='top-left',topright='top-right',bottomleft='bottom-left',bottomright='bottom-right'};value=aliases[value] or value
    if value=='centre-left' then value='center-left' elseif value=='centre-right' then value='center-right' end
    if value=='top-center' then value='top' elseif value=='bottom-center' then value='bottom' end
    return N.validPositions[value] and value or 'top-right'
end
function N.resolveText(text)
    if DTConfig.UI.resolveItemLabels==false or type(text)~='string' or text=='' then return text end
    return (text:gsub('([%w_%-]+)',function(token)
        local label=DT.Inventory and DT.Inventory.GetItemLabel and DT.Inventory.GetItemLabel(token)
        return label and label~=token and label or token
    end))
end
function N.payload(data,description,notifyType)
    if type(data)=='string' then data={title=data,description=description,type=notifyType} else data=DTUtils.copy(data or {}) end
    local p={expiresAt=tonumber(data.expiresAt),serverTime=IsDuplicityVersion() and os.time() or tonumber(data.serverTime),layout=data.layout=='banner' and 'banner' or nil,subtitle=N.resolveText(data.subtitle or data.subject),image=data.image,progress=data.progress,countdown=data.countdown,persistent=data.persistent==true,stack=data.stack,maxVisible=math.max(1,math.min(8,tonumber(DTConfig.UI.notifyMaxVisible) or 5)),id=data.id,title=N.resolveText(data.title),message=N.resolveText(data.message or data.description),type=N.type(data.type),duration=math.max(0,tonumber(data.duration) or DTConfig.UI.notifyDuration or 4500),position=N.position(data.position),size=N.validSizes[data.size] and data.size or (DTConfig.UI.notifySize or 'md'),icon=data.icon,iconColor=data.iconColor,iconAnimation=data.iconAnimation,bgColor=data.bgColor,txtColor=data.txtColor,titleColor=data.titleColor,sound=data.sound,showDuration=data.showDuration,style=data.style,alignIcon=data.alignIcon}
    if not p.title and not p.message then p.title='NOTIFICATION' end
    return p
end
