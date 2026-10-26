from harness import runtime, root
for side in ['client','server']:
 lua=runtime(side=='server')
 lua.execute('''
 logs={};clock=1000;source=10
 function GetGameTimer() return clock end
 function print(message) logs[#logs+1]=message end
 function CreateThread(fn) fn() end
 ''')
 lua.execute((root/f'lib/callback/{side}.lua').read_text())
 lua.globals().event=f'DTlib:callback:{side}:request'
 lua.execute('''
 DT.Callback.Register('failing',function() error('test_function_reference_failure') end)
 handlers[event]('id','failing');assert(#logs==1)
 assert(logs[1]:find('name=failing',1,true) and logs[1]:find('owner=consumer',1,true) and logs[1]:find('source=10',1,true))
 handlers[event]('id','failing');assert(#logs==1)
 clock=11000;handlers[event]('id','failing');assert(#logs==2)
 DT.Callback.Unregister('failing');DT.Callback.Register('failing',function() error('again') end)
 handlers[event]('id','failing');assert(#logs==3)
 ''')
print('Callback failure context includes side/name/owner/source, throttles repeats and resets on unregister PASS')
