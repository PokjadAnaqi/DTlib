local aliases={ox='oxmysql'}
local function A() return DT.Modules.Resolve('database',DTConfig.Adapters.database,{'oxmysql','ghmattimysql'},aliases,'none') end
local function call(m,...)
    local a=A(); if not a or a.resource=='none' then error(('DT.Database.%s: no supported database backend is running'):format(m),3) end
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
