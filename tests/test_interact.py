from harness import load_manifest, root
lua,_=load_manifest(False)
lua.execute('''
 commands={};function RegisterCommand(name,fn) commands[name]=fn end
 function RegisterKeyMapping(...) end
 function IsPauseMenuActive() return false end
 function IsNuiFocused() return false end
 function IsEntityDead() return false end
 function PlayerPedId() return 1 end
 DT.ProgressActive=function() return false end
 DT.UI.IsSuspended=function() return false end
 DTConfig.Interaction={mode='interact',requireLook=false,drawDistance=8,interactDistance=2}
 DT.Inventory.HasItem=function(name,count) return name=='key' and count<=1 end
 DT.Player.HasGroup=function(group) return group=='police' end
''')
lua.execute((root/'modules/target/interact/client.lua').read_text())
lua.execute('''
 local a=DT.Modules.Get('target','dtlib_interact');local p=vec3(0,0,0)
 assert(a:eligible({label='Use'},0,1,p));assert(not a:eligible({label='Use'},0,3,p))
 assert(not a:eligible({groups='admin'},0,1,p))
 assert(a:eligible({groups='police',items={key=1}},0,1,p))
 assert(not a:eligible({items={'missing'}},0,1,p))
 assert(a:eligible({items={'missing','key'},anyItem=true},0,1,p))
 assert(not a:eligible({canInteract=function() error('denied') end},0,1,p))
 assert(not a:eligible({bones={'boot'}},0,1,p))
 local id=a:addBoxZone({coords=p,size=vec3(2,4,2),options={{label='Box'}}})
 assert(a:collect(p,{}).id==id);assert(a:collect(vec3(3,0,0),{})==nil)
 a:removeZone(id);assert(not a:zoneExists(id))
 local poly=a:addPolyZone({points={vec3(-2,-2,0),vec3(2,-2,0),vec3(2,2,0),vec3(-2,2,0)},thickness=2,options={{label='Poly'}}})
 assert(a:collect(p,{}).id==poly);assert(a:collect(vec3(0,0,3),{})==nil);a:removeZone(poly)
 local hits=0
 local id=a:addSphereZone({name='test',coords=p,radius=2,options={{label='Use',onSelect=function(data) assert(data.entity==0);hits=hits+1 end}}})
 assert(a:zoneExists('test'))
 Wait=function() error('test-yield') end;pcall(threads[#threads-1])
 commands['+dtlib_interact']();commands['+dtlib_interact']();assert(hits==1)
 DT.ProgressActive=function() return true end;GetGameTimer=function() return 5000 end
 commands['+dtlib_interact']();assert(hits==1)
 DT.ProgressActive=function() return false end
 a:removeZone(id);commands['+dtlib_interact']();assert(hits==1)
 a:addSphereZone({coords=p,radius=2,options={{label='Owner'}}})
 handlers.onClientResourceStop('consumer');assert(a:collect(p,{})==nil)
''')
print('E interaction geometry, gates, removal, owner cleanup, confirmation revalidation and duplicate/progress suppression PASS')
