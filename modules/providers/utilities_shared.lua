local P=DT.Providers
-- Utilities expose DTlib's existing implementations; Require never executes another resource's source.
P.RegisterUtility('tables',{Copy=DTUtils.copy,Contains=DTUtils.tableContains,Count=function(value) local count=0;for _ in pairs(value or {}) do count=count+1 end;return count end})
P.RegisterUtility('ids',{CreateUniqueId=function(existing) local id=P.Id('id');while existing and existing[id] do id=P.Id('id') end;return id end})
P.RegisterUtility('math',{Clamp=function(value,min,max) return math.max(min,math.min(max,value)) end,Round=function(value,places) local scale=10^(places or 0);return math.floor(value*scale+0.5)/scale end})
for name,api in pairs({callback=DT.Callback,database=DT.Database,logger=DT.Logger,vehicle=DT.Vehicle,waypoint=DT.Waypoint,placement=DT.Placement,zones=DT.Zone,utility=DT.Utils,state=DT.State,resource=DT.Resource}) do P.RegisterUtility(name,api) end
