from harness import root, runtime, load_manifest
import json
catalog=json.loads((root/'docs/ADAPTER_SOURCES.json').read_text())['categories']
passed=0
for category,c in catalog.items():
 for p in c['providers']:
  for side in ['client','server']:
   if not p[side] and not p['shared']:continue
   lua=runtime(side=='server',[p['resource']])
   result=lua.globals().DT.AdapterPack.Get(category,p['name'])
   api,reason=result if isinstance(result,tuple) else (result,None)
   assert api is not None,(category,p['name'],side,reason)
   assert api.GetResourceName()==p['resource']
   passed+=1
print('Full source-pack provider/side initialization:',passed,'PASS')
for server in [False,True]:
 lua,_=load_manifest(server,['lation_ui'])
 lua.execute("function GetControlInstructionalButton(...) return 'KEY' end;function DecorIsRegisteredAsType(...) return true end;function DecorRegister(...) end;function GetGameBuildNumber() return 3258 end")
 for name in ['Ids','Tables','Prints','Math','LA','Callback','Entity','Marker','Shell'] + (['SQL','Logs','Version'] if server else ['Scaleform','Placeable','PlaceableObject','Utility','Raycast','Point','Particle','Anim','Cutscene','Vehicles']):
  result=lua.globals().DT.Ecosystem.Utility(name)
  api,reason=result if isinstance(result,tuple) else (result,None)
  assert api is not None,(name,server,reason)
 assert lua.globals().DT.AdapterPack.Require('../init.lua')[1]=='invalid_path'
 assert lua.globals().DT.AdapterPack.Require('init.lua','untrusted_resource')[1]=='unsupported_source_resource'
print('Shared/side-specific utilities and path guards PASS')
inventory=json.loads((root/'docs/IMPORTED_FILES.json').read_text())
for row in inventory['files']:assert (root/row['dtlib']).is_file(),row
assert len(catalog)==22 and sum(len(c['providers']) for c in catalog.values())==154
print('Complete upstream runtime file inventory:',len(inventory['files']),'PASS')

lua,_=load_manifest(False,['okokNotify'])
lua.execute("""
 DT.Providers.Register('notify','okokNotify',function() return {} end)
 local api=DT.Ecosystem.Get('notify','okokNotify')
 assert(type(api.SendNotify)=='function')
 api.SendNotify('Hello','success',3000)
 local call=calls[#calls];assert(call.resource=='okokNotify' and call.method=='Alert')
 local shell=DT.Ecosystem.Utility('Shell');assert(type(shell)=='table')
""")
print('Missing-method delegation to actual source module PASS')

assert not (root/'integrations').exists()
assert not (root/'modules/ecosystem/pack_catalog.lua').exists()
assert not (root/'modules/ecosystem/pack_runtime.lua').exists()
print('Unified modules layout and consolidated loader PASS')
