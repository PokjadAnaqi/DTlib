from harness import runtime, root
lua=runtime(True)
lua.execute('''
    DT.Version='1.3.1';DTConfig.UpdateCheck={enabled=true}
    resources={'DTlib','DT_questsystem','DT_gather','DT_stopped','other'}
    metadata={DT_questsystem={dependency={'DTlib'}},DT_gather={shared_script={'@DTlib/init.lua'}},DT_stopped={dependency={'DTlib'}}}
    states.DT_questsystem='started';states.DT_gather='started';states.DT_stopped='stopped'
    function GetNumResources() return #resources end
    function GetResourceByFindIndex(i) return resources[i+1] end
    function GetNumResourceMetadata(name,key) return #(metadata[name] and metadata[name][key] or {}) end
    function GetResourceMetadata(name,key,i) return (metadata[name] and metadata[name][key] or {})[i+1] end
    logs={};print=function(s) logs[#logs+1]=s end
    requests=0;timeouts={};SetTimeout=function(_,fn) timeouts[#timeouts+1]=fn end
    PerformHttpRequest=function(url,cb,method,body,headers) requests=requests+1;response=cb;requestHeaders=headers;assert(url:find('/releases/latest',1,true)) end
    json.decode=function(body) if body=='bad' then error('bad json') end;return payload end
''')
lua.execute((root/'modules/version/server/update.lua').read_text())
lua.execute('''
    assert(DT.Update.Compare('1.9.0','1.10.0')==-1)
    assert(DT.Update.Compare('1.3.0-beta.11','1.3.0')==-1)
    assert(DT.Update.Compare('v1.3.0-beta.9','1.3.0-beta.10')==-1)
    assert(DT.Update.Compare('1.3.0+build','1.3.0')==0)
    assert(DT.Update.Compare('bad','1.3.0')==nil)
    assert(#DT.Update.ListConsumers()==2)
    assert(DT.Update.Check());assert(DT.Update.Check()==false and requests==1)
    payload={tag_name='v1.3.2'};response(200,'ok',{etag='test'})
    assert(#logs==5 and logs[1]:find('UPDATE AVAILABLE',1,true))
    assert(logs[4]:find('DT_gather',1,true) and logs[5]:find('DT_questsystem',1,true))
    for _,line in ipairs(logs) do assert(not line:find('Dependency',1,true)) end
    DT.Update.Check();assert(requestHeaders['If-None-Match']=='test');response(304,'',{});assert(#logs==5)
    DT.Update.Check();payload={tag_name='v1.3.3'};response(200,'ok',{});assert(#logs==10)
    DT.Update.Check();response(200,'bad',{});assert(#logs==10)
    DT.Update.Check();payload={tag_name='v1.3.4-beta.1',prerelease=true};response(200,'ok',{});assert(#logs==10)
    DT.Update.Check();local late=response;timeouts[#timeouts]();assert(DT.Update.Check());late(200,'ok',{});response(403,'',{});assert(#logs==10)
    DTConfig.UpdateCheck.includeStopped=true;assert(#DT.Update.ListConsumers()==3)
    DTConfig.UpdateCheck.enabled=false;assert(DT.Update.Check()==false)
''')
print('Central update checker: SemVer, consumer detection/list, one notice, ETag, timeout, errors and release filtering PASS')
