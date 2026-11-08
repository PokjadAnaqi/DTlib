local adapter = { resource = 'oxmysql', publicName = 'oxmysql' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:query(query, payload)
    return exports.oxmysql:query_async(query, payload or {})
end
function adapter:single(query, payload)
    return exports.oxmysql:single_async(query, payload or {})
end
function adapter:scalar(query, payload)
    return exports.oxmysql:scalar_async(query, payload or {})
end
function adapter:insert(query, payload)
    return exports.oxmysql:insert_async(query, payload or {})
end
function adapter:update(query, payload)
    return exports.oxmysql:update_async(query, payload or {})
end
function adapter:prepare(query, payload)
    return exports.oxmysql:prepare_async(query, payload or {})
end
function adapter:rawExecute(query, payload)
    return exports.oxmysql:rawExecute_async(query, payload or {})
end
function adapter:transaction(query, payload)
    return exports.oxmysql:transaction_async(query, payload)
end
DT.Modules.Register('database', 'oxmysql', adapter)
