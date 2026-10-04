local cache = {}

local function token()
    return GetConvar(DTConfig.Discord.tokenConvar, '')
end

local function guildId()
    return GetConvar(DTConfig.Discord.guildIdConvar, '')
end

local function discordId(source)
    local identifier = GetPlayerIdentifierByType(source, 'discord')
    return identifier and identifier:gsub('discord:', '') or nil
end

local function request(method, endpoint, body)
    local auth = token()
    if auth == '' then return nil, 'missing_discord_token' end

    local waiter = promise.new()
    PerformHttpRequest(('https://discord.com/api/v10%s'):format(endpoint), function(status, response)
        if status < 200 or status >= 300 then
            waiter:resolve({ok = false, error = ('discord_http_%s'):format(status), body = response})
            return
        end
        local decoded = response and response ~= '' and json.decode(response) or {}
        waiter:resolve({ok = true, data = decoded})
    end, method, body and json.encode(body) or '', {
        ['Authorization'] = ('Bot %s'):format(auth),
        ['Content-Type'] = 'application/json'
    })

    local result = Citizen.Await(waiter)
    if not result.ok then return nil, result.error end
    return result.data
end

function DT.Discord.GetId(source)
    return discordId(source)
end

function DT.Discord.GetMember(source, force)
    local id = discordId(source)
    local guild = guildId()
    if not id then return nil, 'missing_discord_identifier' end
    if guild == '' then return nil, 'missing_discord_guild_id' end

    local cached = cache[id]
    local now = os.time()
    if not force and cached and cached.expires > now then return cached.data end

    local data, err = request('GET', ('/guilds/%s/members/%s'):format(guild, id))
    if not data then return nil, err end
    cache[id] = {data = data, expires = now + DTConfig.Discord.cacheSeconds}
    return data
end

function DT.Discord.HasRole(source, roleId)
    local member, err = DT.Discord.GetMember(source)
    if not member then return false, err end
    return DTUtils.tableContains(member.roles or {}, tostring(roleId))
end

function DT.Discord.GetAvatar(source)
    local member, err = DT.Discord.GetMember(source)
    if not member then return nil, err end
    local user = member.user or {}
    if not user.id then return nil, 'missing_user' end
    if user.avatar then return ('https://cdn.discordapp.com/avatars/%s/%s.png?size=256'):format(user.id, user.avatar) end
    local index = tonumber(user.discriminator or '0') or 0
    return ('https://cdn.discordapp.com/embed/avatars/%s.png'):format(index % 5)
end
