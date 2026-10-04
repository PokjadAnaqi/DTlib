local A={resource='ghmattimysql',publicName='ghmattimysql'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:query(q,p) return exports.ghmattimysql:executeSync(q,p or {}) end
function A:transaction(q,p) return exports.ghmattimysql:transactionSync(q,p) end
DT.Modules.Register('database','ghmattimysql',A)
