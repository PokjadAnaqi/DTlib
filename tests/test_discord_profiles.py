"""Discord profile hotfix regression tests. No real credentials or API calls."""
from harness import runtime, root

def setup():
    lua=runtime(True)
    lua.execute('''
        cfg={dt_eco_discord_bot_token='test-token'};clock=1000;os.time=function() return clock end
        DTConfig.Discord={cacheSeconds=60,timeoutMs=10000,maxCacheEntries=2}
        GetConvar=function(key,default) return cfg[key] or default end
        identifier='discord:222';GetPlayerIdentifierByType=function() return identifier end
        pendingHttp={};requests=0;timers={}
        SetTimeout=function(_,fn) timers[#timers+1]=fn end
        promise.new=function() return {resolve=function(self,value) self.value=value;self.resolves=(self.resolves or 0)+1 end} end
        PerformHttpRequest=function(url,cb,method,body,headers)
            assert(method=='GET' and headers.Authorization=='Bot test-token')
            requests=requests+1;pendingHttp[#pendingHttp+1]={url=url,callback=cb}
        end
        mode='ok';avatar='avatar_hash';discriminator='0';status=200
        json.decode=function(body)
            if body=='bad' then error('invalid json') end
            if body=='rate' then return {retry_after=2} end
            local user={id=mode=='wrong_user' and '333' or '222',username='Tester',global_name='Test Name',avatar=avatar,discriminator=discriminator}
            if body=='member' then return {user=user,roles={'staff'},nick='Guild Nick'} end
            return user
        end
        Citizen.Await=function(waiter)
            if not waiter.value then
                if mode=='timeout' then timers[#timers]() else
                    local request=pendingHttp[#pendingHttp]
                    local body=mode=='bad' and 'bad' or mode=='rate' and 'rate' or request.url:find('/guilds/',1,true) and 'member' or 'user'
                    request.callback(status,body,{})
                end
            end
            assert(waiter.resolves==1);return waiter.value
        end
    ''')
    lua.execute((root/'lib/discord/server.lua').read_text())
    return lua

lua=setup()
lua.execute('''
    local user=DT.Discord.GetUser(10);assert(user.id=='222' and user.username=='Tester')
    assert(pendingHttp[1].url=='https://discord.com/api/v10/users/222')
    user.username='Changed';assert(DT.Discord.GetUser(10).username=='Tester' and requests==1)
    local avatarUrl=DT.Discord.GetAvatar(10);assert(avatarUrl=='https://cdn.discordapp.com/avatars/222/avatar_hash.png?size=256' and requests==1)
    local member=DT.Discord.GetMember(10);assert(member.profileOnly==true and member.user.id=='222' and #member.roles==0 and requests==1)
    local has,err=DT.Discord.HasRole(10,'staff');assert(has==false and err=='missing_discord_guild_id' and requests==1)
    cfg.dt_eco_discord_guild_id='111'
    member=DT.Discord.GetMember(10);assert(member.profileOnly==nil and member.nick=='Guild Nick' and member.roles[1]=='staff')
    assert(pendingHttp[2].url=='https://discord.com/api/v10/guilds/111/members/222')
    assert(DT.Discord.HasRole(10,'staff') and not DT.Discord.HasRole(10,'other'))
    cfg.dt_eco_discord_guild_id='333';DT.Discord.GetMember(10);assert(requests==3)
    cfg.dt_eco_discord_guild_id='invalid';local value,reason=DT.Discord.HasRole(10,'staff');assert(value==false and reason=='invalid_discord_guild_id')
    -- A bad optional Guild ID must not break the independent user avatar API.
    assert(DT.Discord.GetAvatar(10))
''')
print('Token-only profile/avatar/member compatibility; fail-closed roles; isolated guild/user cache PASS')

lua=setup()
lua.execute('''
    avatar=nil;discriminator='0';assert(DT.Discord.GetAvatar(10)=='https://cdn.discordapp.com/embed/avatars/0.png')
    discriminator='1234';assert(DT.Discord.GetAvatar(10,true)=='https://cdn.discordapp.com/embed/avatars/4.png')
    avatar='a_animated';assert(DT.Discord.GetAvatar(10,true)=='https://cdn.discordapp.com/avatars/222/a_animated.png?size=256')
    identifier=nil;local value,err=DT.Discord.GetAvatar(10);assert(value==nil and err=='missing_discord_identifier')
''')
print('Default/legacy/animated avatar URL and missing Discord identifier PASS')

for mode,expected in [('timeout','discord_timeout'),('bad','discord_invalid_json'),('rate','discord_rate_limited'),('wrong_user','discord_invalid_user')]:
    lua=setup();lua.globals().mode=mode
    if mode=='rate': lua.globals().status=429
    lua.execute('''
        local user,err=DT.Discord.GetUser(10);assert(user==nil);failure=err
        if mode=='timeout' then pendingHttp[1].callback(200,'user',{}) end
    ''')
    assert lua.globals().failure==expected, (mode, lua.globals().failure)
    if mode=='wrong_user':
        lua.execute("mode='ok';assert(DT.Discord.GetUser(10).id=='222' and requests==2)")
    if mode=='rate':
        lua.execute("local value,err=DT.Discord.GetUser(10);assert(value==nil and err=='discord_rate_limited' and requests==1)")

for status,expected in [(401,'discord_http_401'),(403,'discord_http_403'),(404,'discord_http_404')]:
    lua=setup();lua.globals().status=status
    value,err=lua.globals().DT.Discord.GetUser(10)
    assert value is None and err==expected

lua=setup()
lua.execute("cfg.dt_eco_discord_bot_token='';local value,err=DT.Discord.GetAvatar(10);assert(value==nil and err=='missing_discord_token' and requests==0)")
print('Timeout, late response, malformed JSON, 429, wrong-user non-cache, 401/403/404 and missing token PASS')

lua=setup()
lua.execute('''
    Citizen.Await=function(waiter) while not waiter.value do coroutine.yield() end;return waiter.value end
    local first=coroutine.create(function() resultUser=DT.Discord.GetUser(10) end)
    local second=coroutine.create(function() resultAvatar=DT.Discord.GetAvatar(10) end)
    assert(coroutine.resume(first));assert(coroutine.resume(second));assert(requests==1)
    pendingHttp[1].callback(200,'user',{});assert(coroutine.resume(first));assert(coroutine.resume(second))
    assert(resultUser.id=='222' and resultAvatar:find('/222/avatar_hash.png',1,true))
''')
print('Concurrent profile/avatar requests coalesce without Guild ID PASS')
