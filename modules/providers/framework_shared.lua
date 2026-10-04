local P=DT.Providers
for _,definition in ipairs(DTEcosystemCatalog.framework.providers) do
    P.Register('framework',definition.resource,function(resource)
        local adapter=DT.Modules.Get('framework',resource=='native' and 'standalone' or resource)
        assert(adapter,'framework_adapter_missing')
        local api={GetFrameworkName=function() return resource end}
        local function call(method,...)
            if type(adapter[method])~='function' then return nil,'unsupported_method:'..method end
            return adapter[method](adapter,...)
        end
        function api.GetPlayerData(src) return call('getData',src) or {} end
        function api.GetPlayerIdentifier(src) return P.Server and call('getIdentifier',src) or (api.GetPlayerData().citizenid or api.GetPlayerData().identifier) end
        function api.GetPlayerName(src)
            local data=api.GetPlayerData(src);local identity=data.charinfo or data
            return identity.firstname or identity.firstName or call('getName',src),identity.lastname or identity.lastName or ''
        end
        function api.GetPlayerDob(src) local d=api.GetPlayerData(src);return (d.charinfo or d).birthdate or d.dateofbirth end
        function api.GetPlayerPhone(src) local d=api.GetPlayerData(src);return (d.charinfo or d).phone end
        local function job(src) return call(P.Server and 'getJobFor' or 'getJob',src) or {} end
        function api.GetPlayerJob(src)
            local j=job(src);local grade=type(j.grade)=='table' and j.grade or {level=j.grade,name=j.gradeName or j.grade_name}
            return j.name,j.label,grade.name,grade.level or grade.grade or 0
        end
        function api.GetPlayerJobData(src)
            local j=job(src);local grade=type(j.grade)=='table' and j.grade or {level=j.grade,name=j.gradeName or j.grade_name,label=j.gradeLabel}
            return {jobName=j.name,jobLabel=j.label,gradeName=grade.name,gradeLabel=grade.label or grade.name,gradeRank=grade.level or 0,boss=j.isboss or j.boss or false,onDuty=j.onduty or j.onDuty or false}
        end
        function api.GetPlayerGang(src) local j=call(P.Server and 'getGangFor' or 'getGang',src) or {};local g=type(j.grade)=='table' and j.grade or {level=j.grade};return j.name,j.label,g.name,g.level end
        function api.GetPlayerDuty(src) local j=job(src);return j.onduty==true or j.onDuty==true end
        function api.GetPlayerMetadata(src,key) if not P.Server then key=src;src=nil end;return call('getMeta',src,key) end
        if not P.Server then api.GetPlayerMetadata=function(key) return call('getMeta',key) end end
        api.GetPlayerMetaData=api.GetPlayerMetadata
        function api.GetIsPlayerDead(src) local d=api.GetPlayerData(src);local m=d.metadata or {};return m.isdead==true or m.inlaststand==true or d.dead==true end
        function api.GetIsPlayerLoaded(src) local d=api.GetPlayerData(src);return d.citizenid~=nil or d.identifier~=nil end
        function api.GetIsFrameworkAdmin(src) if P.Server then return call('hasPermission',src,'admin')==true end;return call('hasPermission','admin')==true end
        function api.GetPlayerInventory(src) local d=api.GetPlayerData(src);return d.items or d.inventory or {} end
        function api.GetStatus(src,key) if not P.Server then key=src;return call('getMeta',key) end;return call('getMeta',src,key) end
        function api.GetStatusData(src) return api.GetPlayerData(src).metadata or {} end
        for _,status in ipairs({'Hunger','Thirst','Stress'}) do
            local key=status:lower()
            api['Get'..status]=function(src) return P.Server and call('getMeta',src,key) or call('getMeta',key) end
            if P.Server then
                api['Add'..status]=function(src,value) return call('setMeta',src,key,math.max(0,math.min(100,(tonumber(call('getMeta',src,key)) or 0)+(tonumber(value) or 0)))) end
                api['Remove'..status]=function(src,value) return call('setMeta',src,key,math.max(0,math.min(100,(tonumber(call('getMeta',src,key)) or 0)-(tonumber(value) or 0)))) end
            end
        end
        if not P.Server then
            api.Notify=function(message,kind,duration) return DT.Notify({message=message,type=kind,duration=duration}) end
            api.ShowHelpText=function(text) return DT.TextUI.Show({text=text}) end
            api.HideHelpText=function() return DT.TextUI.Hide() end
            api.GetVehicleProperties=DT.Vehicle and DT.Vehicle.GetProperties
            api.SetVehicleProperties=DT.Vehicle and DT.Vehicle.SetProperties
            return api
        end
        local methods={GetPlayer='getPlayer',GetPlayers='getPlayers',GetPlayerByIdentifier='getByIdentifier',GetFrameworkJobs='getJobs',SetPlayerJob='setJob',SetPlayerDuty='setJobDuty',GetAccountBalance='getMoney',AddAccountBalance='addMoney',RemoveAccountBalance='removeMoney',SetPlayerMetadata='setMeta'}
        for public,private in pairs(methods) do local name=private;api[public]=function(...) return call(name,...) end end
        function api.GetPlayerByIdentifier(id) return call(adapter.getByIdentifier and 'getByIdentifier' or 'getByCitizenId',id) end
        function api.ItemList(item) return DT.Ecosystem.Call('inventory','Items',item) end
        api.SetMetadata=function(...) return DT.Ecosystem.Call('inventory','SetMetadata',...) end
        function api.GetPlayerSource(identifier) local player=api.GetPlayerByIdentifier(identifier);return player and (player.source or player.PlayerData and player.PlayerData.source) end
        function api.GetPlayersByJob(name,duty)
            local out={};for _,src in ipairs(DT.Player.GetPlayers()) do local j=job(src);if j.name==name and (duty==nil or api.GetPlayerDuty(src)==duty) then out[#out+1]=src end end;return out
        end
        api.GetPlayerSourcesByJob=api.GetPlayersByJob
        function api.GetJobCount(name,duty) return #api.GetPlayersByJob(name,duty) end
        function api.GetJobCountTotal() local result={};for _,src in ipairs(DT.Player.GetPlayers()) do local name=job(src).name;if name then result[name]=(result[name] or 0)+1 end end;return result end
        function api.SearchJobCountBySource(src) return job(src).name end
        -- Counts derive from framework state, so disconnects cannot leave stale manual counters.
        api.AddJobCount=function() return api.GetJobCountTotal() end
        api.RemoveJobCount=api.AddJobCount
        function api.RegisterUsableItem(name,callback)
            if resource=='es_extended' then return P.Export(resource,'getSharedObject').RegisterUsableItem(name,callback) end
            if resource=='qb-core' then return P.Export(resource,'GetCoreObject').Functions.CreateUseableItem(name,callback) end
            if resource=='qbx_core' then return P.Export(resource,'CreateUseableItem',name,callback) end
            return nil,'unsupported_method:RegisterUsableItem'
        end
        function api.RevivePlayer(src) TriggerClientEvent(resource=='es_extended' and 'esx_ambulancejob:revive' or 'hospital:client:Revive',src);return true end
        for _,method in ipairs({'AddItem','RemoveItem','GetItemCount','GetItemInfo','GetItemBySlot','HasItem'}) do
            local name=method;api[name]=function(...) return DT.Ecosystem.Call('inventory',name,...) end
        end
        api.GetItem=api.GetItemInfo
        function api.GetOwnedVehicles(src)
            local id=api.GetPlayerIdentifier(src);if not id then return {} end
            return DT.Database.Query(resource=='es_extended' and 'SELECT * FROM owned_vehicles WHERE owner = ?' or 'SELECT * FROM player_vehicles WHERE citizenid = ?',{id})
        end
        function api.IsVehicleOwnedByPlayer(src,plate) for _,v in ipairs(api.GetOwnedVehicles(src) or {}) do if DTUtils.trim(v.plate)==DTUtils.trim(plate) then return true end end;return false end
        return api
    end)
end
