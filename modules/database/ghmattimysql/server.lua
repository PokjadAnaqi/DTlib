local adapter = { resource = 'ghmattimysql', publicName = 'ghmattimysql' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:query(query, payload)
    return exports.ghmattimysql:executeSync(query, payload or {})
end
function adapter:transaction(query, payload)
    return exports.ghmattimysql:transactionSync(query, payload)
end
DT.Modules.Register('database', 'ghmattimysql', adapter)
