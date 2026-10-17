"""Regression cases for beta.11; simulated Cfx, not live FiveM validation."""
from harness import runtime, root
from lupa.lua54 import LuaRuntime

for side in ('client', 'server'):
    lua=runtime(side=='server')
    lua.execute('''
        now=1000;lookups=0;definitions={}
        GetGameTimer=function() return now end
        adapter={resource='test',publicName='test',available=function() return true end}
        function adapter:getItemData(item) lookups=lookups+1;return definitions[item] end
        function adapter:items(item) if item then return definitions[item] end;return definitions end
        function adapter:addItem(...) return true end
        function adapter:removeItem(...) return true end
        DTConfig.Adapters.inventory='test';DT.Modules.Register('inventory','test',adapter)
    ''')
    lua.execute((root/f'modules/inventory/{side}.lua').read_text())
    lua.execute((root/'modules/inventory/catalog.lua').read_text())
    lua.execute('''
        assert(DT.Inventory.GetItemData('water')==nil)
        definitions.water={label='Water',image='water.webp',weight=100,rarity='rare',client={image='water.webp'}}
        assert(DT.Inventory.GetItemData('water').label=='Water' and lookups==2)
        local data=DT.Inventory.GetItemData('water');data.client.image='modified'
        assert(DT.Inventory.GetItemData('water').client.image=='water.webp')
        definitions.water.label='Fresh';assert(DT.Inventory.GetItemData('water').label=='Water')
        now=62000;assert(DT.Inventory.GetItemData('water').label=='Fresh')
        adapter2={resource='other',publicName='other',available=function() return true end,getItemData=function() return {label='Other'} end}
        DT.Modules.Register('inventory','other',adapter2);DTConfig.Adapters.inventory='other'
        assert(DT.Inventory.GetItemData('water').label=='Other')
        DTConfig.Adapters.inventory='test';assert(DT.Inventory.GetItemData('water').label=='Fresh')
        definitions.water.label='Restarted'
    ''')
    lua.execute("handlers['%s']('test')"%('onResourceStop' if side=='server' else 'onClientResourceStop'))
    lua.execute('''
        assert(DT.Inventory.GetItemData('water').label=='Restarted')
        local catalog=DT.Inventory.GetCatalog();assert(catalog.water.image=='nui://test/html/images/water.webp' and catalog.water.rarity=='rare')
        definitions={items={{name='z',label='Z'},{name='a',label='A'}}}
        local array=DT.Inventory.GetCatalog({asArray=true});assert(#array==2 and array[1].name=='a')
        assert(DT.Inventory.GetItemImage('x',{image='javascript:alert(1)'})==nil)
        assert(DT.Inventory.Supports('Items') and not DT.Inventory.Supports('CanCarry'))
    ''')
    if side=='server':
        lua.execute('''
            for _,count in ipairs({-1,0,0.5,math.huge,0/0,'bad'}) do
                local ok,err=DT.Inventory.AddItem(10,'water',count);assert(ok==false and err=='invalid_count')
                ok,err=DT.Inventory.RemoveItem(10,'water',count);assert(ok==false and err=='invalid_count')
            end
            local ok,err=DT.Inventory.CanCarry(10,'water',1);assert(ok==nil and err=='unsupported_backend')
            assert(DT.Inventory.AddItem(10,'water',1)==true)
            adapter.canCarry=function() return false,'too_heavy' end
            ok,err=DT.Inventory.AddItem(10,'water',1);assert(ok==false and err=='too_heavy')
        ''')
print('Inventory misses, deep-copy cache, TTL, provider changes, lifecycle, catalog, counts and capabilities PASS')

lua=runtime(True)
lua.execute('''
    cfg={dt_eco_discord_bot_token='test-token',guild='111'}
    DTConfig.Discord={tokenConvar='dt_eco_discord_bot_token',guildIdConvar='guild',cacheSeconds=60}
    GetConvar=function(k,default) return cfg[k] or default end
    GetPlayerIdentifierByType=function() return 'discord:222' end
    requests=0;timers={};responses={}
    SetTimeout=function(_,fn) timers[#timers+1]=fn end
    promise.new=function() return {resolve=function(self,value) self.value=value;self.resolved=(self.resolved or 0)+1 end} end
    PerformHttpRequest=function(url,cb) requests=requests+1;responses[#responses+1]=cb end
    Citizen.Await=function(waiter)
        if not waiter.value then
            if mode=='timeout' then timers[#timers]()
            elseif mode=='malformed' then responses[#responses](200,'bad')
            elseif mode=='rate' then responses[#responses](429,'rate')
            else responses[#responses](200,'ok') end
        end
        assert(waiter.resolved==1);return waiter.value
    end
    json.decode=function(s) if s=='bad' then error('bad json') end;if s=='rate' then return {retry_after=1} end;return {roles={'staff'},user={id='222',discriminator='0'}} end
''')
lua.execute((root/'lib/discord/server.lua').read_text())
lua.execute('''
    mode='timeout';local data,err=DT.Discord.GetMember(10);assert(data==nil and err=='discord_timeout')
    responses[#responses](200,'ok') -- late callback must be ignored
    mode='malformed';data,err=DT.Discord.GetMember(10);assert(data==nil and err=='discord_invalid_json')
    mode='ok';data=DT.Discord.GetMember(10);assert(data.user.id=='222')
    local before=requests;data.user.id='modified';assert(DT.Discord.GetMember(10).user.id=='222' and requests==before)
    cfg.guild='333';assert(DT.Discord.GetMember(10) and requests==before+1)
    assert(DT.Discord.HasRole(10,'staff') and DT.Discord.GetAvatar(10):find('/0.png',1,true))
    DT.Discord.ClearCache();mode='rate';data,err=DT.Discord.GetMember(10);assert(data==nil and err=='discord_rate_limited')
    before=requests;data,err=DT.Discord.GetMember(10);assert(data==nil and err=='discord_rate_limited' and requests==before)
''')
print('Discord timeout, late callback, invalid JSON, guild cache isolation and rate-limit cooldown PASS')

lua=runtime(resources=())
lua.execute('''
    currentOwner='first';GetInvokingResource=function() return currentOwner end
    LocalPlayer.state.set=function(self,key,value) self[key]=value end
    IsHudHidden=function() return false end;IsRadarHidden=function() return false end
    DisplayHud=function() end;DisplayRadar=function() end
''')
lua.execute((root/'modules/ui_suspend/client.lua').read_text())
lua.execute('''
    first=DT.UI.Suspend('inventory');currentOwner='second';second=DT.UI.Suspend('placement')
    handlers.onClientResourceStop('first');assert(DT.UI.IsSuspended())
    handlers.onClientResourceStop('second');assert(not DT.UI.IsSuspended() and LocalPlayer.state.dtlibUiSuspended==false)
''')
print('UI stop releases only the stopped resource owner and restores on final release PASS')

for server in (False,True):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().server=server
    lua.execute('''
        handlers={};threads={};object={Version='old',Inventory={Name=function() return 'old' end},UI={},Input={},Alert={}}
        function GetCurrentResourceName() return 'consumer' end
        function GetResourceState() return 'started' end
        function GetGameTimer() return 0 end
        function IsDuplicityVersion() return server end
        function AddEventHandler(name,fn) handlers[name]=handlers[name] or {};table.insert(handlers[name],fn) end
        function TriggerEvent(name,...) for _,fn in ipairs(handlers[name] or {}) do fn(...) end end
        function CreateThread(fn) threads[#threads+1]=fn end
        function Wait() end
        exports={DTlib={GetObject=function() return object end,RegisterAdminTool=function() return true end}}
    ''')
    lua.execute((root/'init.lua').read_text())
    lua.execute('''
        local name=DT.Inventory.Name;assert(name()=='old' and DT.IsReady())
        TriggerEvent(server and 'onResourceStop' or 'onClientResourceStop','DTlib')
        local value,err=name();assert(value==nil and err=='dtlib_unavailable' and not DT.IsReady())
        object={Version='new',Inventory={Name=function() return 'new' end}}
        TriggerEvent(server and 'onResourceStart' or 'onClientResourceStart','DTlib')
        threads[#threads]();assert(DT.IsReady() and name()=='new' and DT.Version=='new')
    ''')
print('Consumer cached function references rebind after DTlib restart on both sides PASS')

lua=runtime(True)
lua.execute('''
    DTConfig.Discord={tokenConvar='token',guildIdConvar='guild'}
    GetConvar=function(k) return k=='token' and 'test-token' or '111' end
    GetPlayerIdentifierByType=function() return 'discord:222' end
    timers={};SetTimeout=function(_,fn) timers[#timers+1]=fn end
    requests=0;PerformHttpRequest=function(_,fn) requests=requests+1;response=fn end
    promise.new=function() return {resolve=function(self,value) self.value=value end} end
    Citizen.Await=function(waiter) while not waiter.value do coroutine.yield() end;return waiter.value end
    json.decode=function() return {user={id='222'}} end
''')
lua.execute((root/'lib/discord/server.lua').read_text())
lua.execute('''
    one=coroutine.create(function() first=DT.Discord.GetMember(10) end)
    two=coroutine.create(function() second=DT.Discord.GetMember(10,true) end)
    assert(coroutine.resume(one));assert(coroutine.resume(two));assert(requests==1)
    response(200,'ok');assert(coroutine.resume(one));assert(coroutine.resume(two))
    assert(first.user.id=='222' and second.user.id=='222')
''')
print('Concurrent Discord member lookups share one HTTP request PASS')

for mode in ('ok','timeout','failed'):
    lua=runtime(True)
    lua.globals().mode=mode
    lua.execute('''
        time=0;GetGameTimer=function() return time end;Wait=function(ms) time=time+ms end
        promise.new=function() return {resolve=function(self,value) self.value=value end} end
        SetTimeout=function(_,fn) timeout=fn end
        CreateThread=function(fn) worker=fn end
        Citizen.Await=function(waiter)
            if mode=='timeout' then timeout() else worker() end
            assert(waiter.value);return waiter.value
        end
        DT.Modules.Register('database','test',{resource='test',publicName='test',available=function() return true end,
            scalar=function() if mode=='failed' then error('driver failure') end;return 1 end})
        DTConfig.Adapters.database='test'
    ''')
    lua.execute((root/'modules/database/server.lua').read_text())
    lua.execute('''
        local ok,err=DT.Database.AwaitReady(1000)
        assert(ok==(mode=='ok'))
        if mode=='timeout' then assert(err=='database_timeout');worker() end
        if mode=='failed' then assert(err=='database_unavailable') end
        DTConfig.Adapters.database='none';ok,err=DT.Database.AwaitReady(100)
        assert(ok==false and err=='database_timeout' and time>=100)
    ''')
print('Database connection probe success, driver failure, missing driver and caller timeout PASS')
