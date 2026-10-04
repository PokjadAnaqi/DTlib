from harness import load_manifest
lua,_=load_manifest(True,['oxmysql'])
lua.execute("""
 assert(DT.Database.Available() and DT.Database.Name()=='oxmysql')
 DT.Database.Query('SELECT ?', {7})
 local call=calls[#calls];assert(call.resource=='oxmysql' and call.method=='query_async' and call.args[2]=='SELECT ?' and call.args[3][1]==7)
 states.oxmysql='starting';assert(not DT.Database.Available())
 local ok,reason=pcall(DT.Database.Query,'SELECT 1')
 assert(not ok and reason:find('oxmysql=starting',1,true) and reason:find('ensure oxmysql',1,true))
 states.oxmysql='started';assert(DT.Database.Available())
 local status=DT.Database.Status();assert(status.provider=='oxmysql' and status.resources.oxmysql=='started')
 states.oxmysql='stopped';assert(not DT.Database.Available())
""")
print('Database selection, live state changes, query routing and diagnostics PASS')
