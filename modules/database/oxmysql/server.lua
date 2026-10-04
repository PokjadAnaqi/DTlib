local A={resource='oxmysql',publicName='oxmysql'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:query(q,p) return exports.oxmysql:query_async(q,p or {}) end
function A:single(q,p) return exports.oxmysql:single_async(q,p or {}) end
function A:scalar(q,p) return exports.oxmysql:scalar_async(q,p or {}) end
function A:insert(q,p) return exports.oxmysql:insert_async(q,p or {}) end
function A:update(q,p) return exports.oxmysql:update_async(q,p or {}) end
function A:prepare(q,p) return exports.oxmysql:prepare_async(q,p or {}) end
function A:rawExecute(q,p) return exports.oxmysql:rawExecute_async(q,p or {}) end
function A:transaction(q,p) return exports.oxmysql:transaction_async(q,p) end
DT.Modules.Register('database','oxmysql',A)
