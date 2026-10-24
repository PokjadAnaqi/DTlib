"""Weather registry, source-loader and logger regression tests (mock Cfx runtime)."""
from pathlib import Path
import json
import re
from harness import runtime

ROOT = Path(__file__).resolve().parents[1]

def weather_runtime(server=False, resources=()):
    lua = runtime(server, resources)
    lua.execute((ROOT / 'settings/sharedConfig.lua').read_text())
    lua.execute('''
      function RegisterCommand(...) end
      function GetClockHours() return 15 end
      function GetClockMinutes() return 20 end
      function GetClockSeconds() return 25 end
      function IsNextWeatherType() return false end
      function GetPrevWeatherTypeHashName() return 0 end
      function GetNextWeatherTypeHashName() return 0 end
    ''')
    manifest = (ROOT / 'fxmanifest.lua').read_text()
    block = re.search(('server' if server else 'client') + r'_scripts\s*\{(.*?)\}', manifest, re.S)[1]
    for path in re.findall(r"'([^']+)'", block):
        if path.startswith('modules/weather/') or path == 'modules/providers/world_client.lua' or path == 'lib/logger/server.lua':
            source = (ROOT / path).read_text()
            lua.execute(re.sub(r'`([^`]+)`', lambda m: 'joaat(' + repr(m[1]) + ')', source))
    return lua

for server in (False, True):
    lua = weather_runtime(server, ['cd_easytime', 'qb-weathersync'])
    lua.execute('''
      exports.cd_easytime={GetAllData=function() return {weather='rain',hours=8,mins=7} end}
      assert(DT.Weather.Name()=='cd_easytime')
      assert(DT.Weather.GetCurrent()=='RAIN')
      states.cd_easytime='starting'; assert(DT.Weather.Name()=='qb-weathersync')
      states.cd_easytime='started'; assert(DT.Weather.Name()=='cd_easytime')
      states['Renewed-Weathersync']='started'; assert(DT.Weather.Name()=='Renewed-Weathersync')
      DTConfig.Adapters.weather='easytime'; assert(DT.Weather.Name()=='cd_easytime')
      DTConfig.Adapters.weather='qb'; assert(DT.Weather.Name()=='qb-weathersync')
      DTConfig.Adapters.weather='renewed'; assert(DT.Weather.Name()=='Renewed-Weathersync')
      DTConfig.Adapters.weather='auto'
    ''')
    if server:
        lua.execute('''
          assert(DT.Logger.GetRuntimeStatus().weather==DT.Weather.Name())
          states['Renewed-Weathersync']='stopped'
          assert(DT.Logger.GetRuntimeStatus().weather=='cd_easytime')
          DTConfig.Adapters.weather='CD_EASYTIME'
          assert(DT.Logger.GetRuntimeStatus().weather=='cd_easytime')
          DTConfig.Adapters.weather='auto'
        ''')
    else:
        lua.execute('''
          states['Renewed-Weathersync']='stopped'
          assert(DT.Ecosystem.Provider('weather')=='cd_easytime')
          assert(DT.AdapterPack.Provider('weather')=='cd_easytime')
          events={};function TriggerEvent(name,value) events[#events+1]={name,value} end
          assert(DT.Ecosystem.Weather.ToggleSync(true))
          assert(events[#events][1]=='cd_easytime:PauseSync' and events[#events][2]==false)
          assert(DT.AdapterPack.Weather.ToggleSync(false))
          assert(events[#events][2]==true)
          DTConfig.Adapters.weather='qb'
          assert(DT.Ecosystem.Provider('weather')=='qb-weathersync')
          assert(DT.AdapterPack.Provider('weather')=='qb-weathersync')
          assert(DT.AdapterPack.Weather.ToggleSync(true))
          assert(events[#events][1]=='qb-weathersync:client:EnableSync')
          DTConfig.Adapters.weather='auto'
          assert(DT.AdapterPack.Weather.ToggleSync(true))
          assert(events[#events][1]=='cd_easytime:PauseSync' and events[#events][2]==false)
        ''')
    lua.execute('''
      states.cd_easytime='stopped'; states['Renewed-Weathersync']='stopped'
      assert(DT.Weather.Name()=='qb-weathersync')
      states['qb-weathersync']='stopped'; assert(DT.Weather.Name()=='native')
    ''')
    if server:
        lua.execute("assert(DT.Logger.GetRuntimeStatus().weather=='native')")
    else:
        lua.execute("assert(DT.Ecosystem.Provider('weather')=='native');assert(DT.AdapterPack.Provider('weather')=='native')")

folders = {p.name for p in (ROOT / 'modules/weather').iterdir() if p.is_dir() and any(p.rglob('*.lua'))}
assert folders == {'cd_easytime', 'qb-weathersync', 'renewed-weathersync', 'native'}, folders
sources = json.loads((ROOT / 'docs/ADAPTER_SOURCES.json').read_text())['categories']['weather']['providers']
for provider in sources:
    for path in provider['client'] + provider['server'] + provider['shared']:
        assert (ROOT / path).is_file(), path
print('Weather consolidation, resource states, Easytime/QB aliases, runtime log and both registries PASS')
