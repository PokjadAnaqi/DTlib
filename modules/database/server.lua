local aliases={ox='oxmysql'}
local function A() return DT.Modules.Resolve('database',DTConfig.Adapters.database,{'oxmysql','ghmattimysql'},aliases,'none') end
local function call(m,...)
    local a=A(); if not a or a.resource=='none' then error(('DT.Database.%s: no supported database backend is running (configured=%s, oxmysql=%s, ghmattimysql=%s). Start a supported driver before DTlib, for example ensure oxmysql; inspect the driver startup log if it is not started.'):format(m,tostring(DTConfig.Adapters.database),GetResourceState('oxmysql'),GetResourceState('ghmattimysql')),3) end
    local fn=a[m]; if type(fn)~='function' then return nil,'unsupported_backend' end; return fn(a,...)
end
function DT.Database.Name() local a=A(); return a and a.publicName or 'none' end
function DT.Database.Available() local a=A(); return a and a.resource~='none' end
function DT.Database.Query(q,p) return call('query',q,p or {}) end
DT.Database.Execute=DT.Database.Query
function DT.Database.Single(q,p) local a=A(); if a and a.single then return a:single(q,p or {}) end; local rows=DT.Database.Query(q,p); return rows and rows[1] or nil end
function DT.Database.Scalar(q,p) local a=A(); if a and a.scalar then return a:scalar(q,p or {}) end; local row=DT.Database.Single(q,p); if type(row)~='table' then return row end; for _,v in pairs(row) do return v end end
function DT.Database.Insert(q,p) local a=A(); if a and a.insert then return a:insert(q,p or {}) end; local r=DT.Database.Query(q,p); return r and (r.insertId or r.insert_id) end
function DT.Database.Update(q,p) local a=A(); if a and a.update then return a:update(q,p or {}) end; local r=DT.Database.Query(q,p); return r and (r.affectedRows or r.changedRows) or 0 end
function DT.Database.Prepare(q,p) local a=A(); if a and a.prepare then return a:prepare(q,p or {}) end; return DT.Database.Query(q,p) end
function DT.Database.RawExecute(q,p) local a=A(); if a and a.rawExecute then return a:rawExecute(q,p or {}) end; return DT.Database.Query(q,p) end
function DT.Database.Transaction(q,p) return call('transaction',q,p) end
DT.Database.query=DT.Database.Query; DT.Database.execute=DT.Database.Query; DT.Database.single=DT.Database.Single; DT.Database.scalar=DT.Database.Scalar; DT.Database.insert=DT.Database.Insert; DT.Database.update=DT.Database.Update; DT.Database.prepare=DT.Database.Prepare; DT.Database.rawExecute=DT.Database.RawExecute; DT.Database.transaction=DT.Database.Transaction

function DT.Database.Status()
    return {configured=DTConfig.Adapters.database,provider=DT.Database.Name(),resources={oxmysql=GetResourceState('oxmysql'),ghmattimysql=GetResourceState('ghmattimysql')}}
end

-- A running driver is not necessarily connected. Probe it without blocking the caller forever.
function DT.Database.AwaitReady(timeoutMs)
    timeoutMs=tonumber(timeoutMs) or 10000
    if timeoutMs~=timeoutMs or timeoutMs<0 or timeoutMs==math.huge then return false,'invalid_timeout' end
    local deadline=GetGameTimer()+math.min(timeoutMs,60000)
    while not DT.Database.Available() do
        if GetGameTimer()>=deadline then return false,'database_timeout' end
        Wait(50)
    end
    local waiter=promise.new();local settled=false
    local function finish(ok,err)
        if settled then return end;settled=true;waiter:resolve({ok=ok,error=err})
    end
    SetTimeout(math.max(0,deadline-GetGameTimer()),function() finish(false,'database_timeout') end)
    CreateThread(function()
        local ok,value=pcall(DT.Database.Scalar,'SELECT 1',{})
        finish(ok and tonumber(value)==1,not ok and 'database_unavailable' or tonumber(value)~=1 and 'database_not_ready' or nil)
    end)
    local result=Citizen.Await(waiter);return result.ok,result.error
end
