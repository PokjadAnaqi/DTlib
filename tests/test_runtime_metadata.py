from harness import load_manifest, root
import re
version=re.search(r"^version '([^']+)'",(root/'fxmanifest.lua').read_text(),re.M)[1]
lua,_=load_manifest(True,['DT_interact','ox_target'])
lua.globals().manifestVersion=version
lua.execute("function GetResourceMetadata(resource,key,index) assert(resource=='DTlib' and key=='version' and index==0);return manifestVersion end")
lua.execute((root/'shared/core.lua').read_text())
lua.execute('''
assert(DT.Version==manifestVersion)
assert(DT.GetVersion()==manifestVersion)
DTConfig.Adapters.target='auto'
local status=DT.Logger.GetRuntimeStatus()
assert(status.version==manifestVersion and status.target=='DT_interact')
DTConfig.Adapters.target='ox';assert(DT.Logger.GetRuntimeStatus().target=='ox_target')
DTConfig.Adapters.target='dt_interact';assert(DT.Logger.GetRuntimeStatus().target=='DT_interact')
DTConfig.Interaction.mode='interact';DTConfig.Adapters.target='ox';assert(DT.Logger.GetRuntimeStatus().target=='DT_interact')
DTConfig.Interaction.mode='target';DTConfig.Adapters.target='auto';states.DT_interact='missing'
assert(DT.Logger.GetRuntimeStatus().target=='ox_target')
''')
print('Runtime version follows manifest; boot status prefers standalone DT_interact over target aliases PASS')
