local cache,pending,cooldowns={},{},{}
local inFlight=0
local function config() return DTConfig.Discord or {} end
local function bounded(value,default,min,max)
    value=tonumber(value)
    if not value or value~=value then value=default end
    return math.max(min,math.min(max,value))
end
local function token() return GetConvar(config().tokenConvar or 'dt_eco_discord_bot_token','') end
local function guildId() return GetConvar(config().guildIdConvar or 'dt_eco_discord_guild_id','') end
local function discordId(source)
    local identifier=GetPlayerIdentifierByType(source,'discord')
    return identifier and identifier:match('^discord:(%d+)$') or nil
end
local function request(endpoint)
    local auth=token()
    if auth=='' then return nil,'missing_discord_token' end
    local now=os.time()
    if now<(cooldowns.global or 0) or now<(cooldowns.route or 0) then return nil,'discord_rate_limited' end
    if inFlight>=32 then return nil,'discord_busy' end
    inFlight=inFlight+1
    local waiter=promise.new()
    local settled=false
    local function finish(result)
        if settled then return end
        settled=true;inFlight=inFlight-1;waiter:resolve(result)
    end
    SetTimeout(bounded(config().timeoutMs,10000,1000,60000),function() finish({error='discord_timeout'}) end)
    local ok=pcall(PerformHttpRequest,'https://discord.com/api/v10'..endpoint,function(status,response,headers)
        if settled then return end
        status=tonumber(status) or 0
        local data={}
        if response and response~='' then
            local decoded,value=pcall(json.decode,response)
            if decoded then data=value else
                finish({error=status>=200 and status<300 and 'discord_invalid_json' or ('discord_http_%s'):format(status)});return
            end
        end
        if status==429 then
            local delay=type(data)=='table' and tonumber(data.retry_after)
            delay=delay or (type(headers)=='table' and tonumber(headers['retry-after']))
            local key=type(data)=='table' and data.global==true and 'global' or 'route'
            cooldowns[key]=os.time()+math.ceil(bounded(delay,5,1,300))
            finish({error='discord_rate_limited'});return
        end
        if status<200 or status>=300 then finish({error=('discord_http_%s'):format(status)});return end
        if type(data)~='table' then finish({error='discord_invalid_json'});return end
        finish({data=data})
    end,'GET','',{['Authorization']='Bot '..auth,['Content-Type']='application/json'})
    if not ok then finish({error='discord_request_failed'}) end
    local result=Citizen.Await(waiter)
    return result.data,result.error
end
function DT.Discord.GetId(source) return discordId(source) end
local function cachedRequest(key,endpoint,force)
    local now=os.time()
    if not force and cache[key] and cache[key].expires>now then return DTUtils.copy(cache[key].data) end
    if pending[key] then
        local result=Citizen.Await(pending[key]);return result.data and DTUtils.copy(result.data),result.error
    end
    local waiter=promise.new();pending[key]=waiter
    local ok,data,err=pcall(request,endpoint)
    if not ok then data=nil;err='discord_request_failed' end
    if data and key:sub(1,5)=='user:' and tostring(data.id or '')~=key:sub(6) then
        data=nil;err='discord_invalid_user'
    end
    if data then
        local total,oldest,oldestExpiry=0,nil,math.huge
        for k,entry in pairs(cache) do
            if entry.expires<=now then cache[k]=nil else
                total=total+1;if entry.expires<oldestExpiry then oldest,oldestExpiry=k,entry.expires end
            end
        end
        if total>=bounded(config().maxCacheEntries,512,1,10000) and oldest then cache[oldest]=nil end
        cache[key]={data=data,expires=os.time()+bounded(config().cacheSeconds,60,0,3600)}
    end
    pending[key]=nil;waiter:resolve({data=data,error=err})
    return data and DTUtils.copy(data),err
end
function DT.Discord.GetUser(source,force)
    local id=discordId(source)
    if not id then return nil,'missing_discord_identifier' end
    local data,err=cachedRequest('user:'..id,('/users/%s'):format(id),force)
    if not data then return nil,err end
    if tostring(data.id or '')~=id then return nil,'discord_invalid_user' end
    return data
end
function DT.Discord.GetMember(source,force)
    local id,guild=discordId(source),guildId()
    if not id then return nil,'missing_discord_identifier' end
    if guild=='' then
        -- Compatibility for profile consumers that already read member.user.
        -- This is not proof of guild membership and must never grant a role.
        local user,err=DT.Discord.GetUser(source,force)
        if not user then return nil,err end
        return {user=user,roles={},profileOnly=true}
    end
    if not guild:match('^%d+$') then return nil,'invalid_discord_guild_id' end
    return cachedRequest('member:'..guild..':'..id,('/guilds/%s/members/%s'):format(guild,id),force)
end
function DT.Discord.ClearCache() cache={};return true end
function DT.Discord.HasRole(source,roleId)
    if guildId()=='' then return false,'missing_discord_guild_id' end
    local member,err=DT.Discord.GetMember(source)
    if not member then return false,err end
    return DTUtils.tableContains(member.roles or {},tostring(roleId))
end
function DT.Discord.GetAvatar(source,force)
    -- Global avatars belong to the user, not to a guild member.
    local user,err=DT.Discord.GetUser(source,force)
    if not user and guildId()~='' then
        local member,memberErr=DT.Discord.GetMember(source,force)
        user=member and member.user
        err=memberErr or err
    end
    if not user then return nil,err end
    if not user.id then return nil,'missing_user' end
    if user.avatar then return ('https://cdn.discordapp.com/avatars/%s/%s.png?size=256'):format(user.id,user.avatar) end
    local discriminator=tonumber(user.discriminator) or 0
    local index=discriminator~=0 and discriminator%5 or ((tonumber(user.id) or 0)//4194304)%6
    return ('https://cdn.discordapp.com/embed/avatars/%s.png'):format(index)
end
