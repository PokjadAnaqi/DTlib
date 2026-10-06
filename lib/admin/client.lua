DT.Admin = DT.Admin or {}
local registered = {}
local function validId(value) return type(value)=='string' and value:match('^[%w_%-%.]+$') ~= nil end
function DT.Admin.RegisterTool(data)
    if type(data)~='table' or not validId(data.id) or type(data.label)~='string' or data.label=='' or type(data.command)~='string' or data.command=='' then return false,'invalid_tool' end
    local resource=GetInvokingResource() or GetCurrentResourceName()
    if resource=='DTlib' then return false,'consumer_resource_required' end
    local key=resource..':'..data.id
    registered[key]={id=data.id,label=data.label,description=tostring(data.description or ''),command=data.command,resource=resource}
    return true
end
function DT.Admin.UnregisterTool(id)
    if type(id)~='string' then return false end
    local caller=GetInvokingResource() or GetCurrentResourceName()
    local key=caller..':'..id
    if not registered[key] then return false end
    registered[key]=nil;return true
end
exports('RegisterAdminTool',function(data) return DT.Admin.RegisterTool(data) end)
exports('UnregisterAdminTool',function(id) return DT.Admin.UnregisterTool(id) end)
RegisterNetEvent('DTlib:client:adminOpen',function()
    local items={}
    for _,tool in pairs(registered) do
        if GetResourceState(tool.resource)=='started' then
            items[#items+1]={label=tool.label,description=tool.description~='' and tool.description or ('Open %s'):format(tool.resource),command=tool.command}
        end
    end
    table.sort(items,function(a,b)return a.label:lower()<b.label:lower()end)
    if #items==0 then items[1]={label='No admin tools registered',description='Register a tool from its resource using exports.DTlib:RegisterAdminTool(...)',disabled=true} end
    DT.Menu.Open({id='dtlib_admin_hub',title='DT SCRIPT ADMIN',subtitle='Registered ecosystem tools',position='center',items=items})
end)
RegisterCommand('dtlib:admin',function() TriggerServerEvent('DTlib:server:adminOpen') end,false)
