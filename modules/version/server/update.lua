-- One GitHub request for DTlib, never one request per consumer.
DT.Update = DT.Update or {}
local U=DT.Update
local url='https://api.github.com/repos/PokjadAnaqi/DTlib/releases/latest'
local download='https://github.com/PokjadAnaqi/DTlib/releases/latest'
local busy=false
local sequence=0
local lastPrinted,etag,cached
local function config() return DTConfig.UpdateCheck or {} end
local function parse(value)
    if type(value)~='string' then return nil end
    value=value:gsub('^v',''):gsub('%+[%w%.%-]+$','')
    local base,pre=value:match('^(%d+%.%d+%.%d+)%-([%w%.%-]+)$')
    base=base or value
    local a,b,c=base:match('^(%d+)%.(%d+)%.(%d+)$')
    if not a then return nil end
    local result={tonumber(a),tonumber(b),tonumber(c),pre=pre}
    for _,part in ipairs({a,b,c}) do if #part>1 and part:sub(1,1)=='0' then return nil end end
    if pre then
        if pre:sub(1,1)=='.' or pre:sub(-1)=='.' or pre:find('..',1,true) then return nil end
        result.ids={}
        for id in pre:gmatch('[^.]+') do
            if id:match('^%d+$') and #id>1 and id:sub(1,1)=='0' then return nil end
            result.ids[#result.ids+1]=id
        end
    end
    return result
end
function U.Compare(a,b)
    a,b=parse(a),parse(b)
    if not a or not b then return nil,'invalid_version' end
    for i=1,3 do if a[i]~=b[i] then return a[i]<b[i] and -1 or 1 end end
    if a.pre==b.pre then return 0 end
    if not a.pre then return 1 end
    if not b.pre then return -1 end
    for i=1,math.max(#a.ids,#b.ids) do
        local x,y=a.ids[i],b.ids[i]
        if not x then return -1 end;if not y then return 1 end
        if x~=y then
            local xn=x:match('^%d+$') and tonumber(x)
            local yn=y:match('^%d+$') and tonumber(y)
            if xn and yn then return xn<yn and -1 or 1 end
            if xn then return -1 end;if yn then return 1 end
            return x<y and -1 or 1
        end
    end
    return 0
end
local function usesDTlib(resource)
    if not GetNumResourceMetadata then return false end
    for _,key in ipairs({'dependency','shared_script','server_script','client_script'}) do
        for i=0,(GetNumResourceMetadata(resource,key) or 0)-1 do
            local value=tostring(GetResourceMetadata(resource,key,i) or ''):lower()
            if (key=='dependency' and value=='dtlib') or value:match('^@dtlib/') then return true end
        end
    end
    return false
end
function U.ListConsumers()
    local out={}
    if not GetNumResources or not GetResourceByFindIndex then return out end
    for i=0,GetNumResources()-1 do
        local name=GetResourceByFindIndex(i)
        if name and name~=GetCurrentResourceName() then
            local state=GetResourceState(name)
            if (state=='started' or state=='starting' or config().includeStopped==true) and usesDTlib(name) then
                out[#out+1]={name=name,version=GetResourceMetadata(name,'version',0),state=state}
            end
        end
    end
    table.sort(out,function(a,b) return a.name:lower()<b.name:lower() end)
    return out
end
local function log(message) print('^3[DTlib:UPDATE]^7 '..message) end
local function report(latest)
    local installed=DT.Version or GetResourceMetadata(GetCurrentResourceName(),'version',0)
    local comparison=U.Compare(installed,latest)
    if comparison==nil then return false,'invalid_version' end
    local key=tostring(installed)..':'..latest
    if key==lastPrinted then return true end
    lastPrinted=key
    if comparison<0 then
        log(('UPDATE AVAILABLE | Installed: %s | Latest: %s'):format(installed,latest))
        log('Download: '..download)
    elseif comparison==0 then
        if config().logUpToDate==false then return true end
        log(('Up to date | Installed: %s | Latest: %s'):format(installed,latest))
    else
        if config().logUpToDate==false then return true end
        log(('Installed: %s | Latest official: %s'):format(installed,latest))
    end
    if config().listConsumers~=false then
        local consumers=U.ListConsumers()
        log(('Scripts using DTlib (%s):'):format(#consumers))
        for _,entry in ipairs(consumers) do log('  - '..entry.name) end
    end
    return true
end
function U.Check()
    if config().enabled==false then return false,'disabled' end
    if busy then return false,'busy' end
    busy=true;sequence=sequence+1;local current=sequence
    SetTimeout(10000,function() if current==sequence then busy=false;sequence=sequence+1 end end)
    local headers={['Accept']='application/vnd.github+json',['User-Agent']='DTlib-UpdateChecker'}
    if etag then headers['If-None-Match']=etag end
    local ok=pcall(PerformHttpRequest,url,function(status,body,responseHeaders)
        if current~=sequence then return end
        busy=false;sequence=sequence+1
        if status==304 and cached then report(cached);return end
        if status~=200 then return end
        local decoded,data=pcall(json.decode,body or '')
        if not decoded or type(data)~='table' or data.draft==true or data.prerelease==true or not parse(data.tag_name) then return end
        cached=data.tag_name
        etag=type(responseHeaders)=='table' and (responseHeaders.ETag or responseHeaders.etag) or nil
        report(cached)
    end,'GET','',headers)
    if not ok then busy=false;sequence=sequence+1;return false,'request_failed' end
    return true
end
exports('CheckForUpdates',U.Check)
exports('GetDTlibConsumers',U.ListConsumers)
CreateThread(function()
    Wait(5000)
    while config().enabled~=false do
        U.Check()
        local minutes=tonumber(config().intervalMinutes) or 60
        if minutes~=minutes then minutes=60 end
        Wait(math.floor(math.max(5,math.min(1440,minutes)))*60000)
    end
end)
