from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = (ROOT / 'fxmanifest.lua').read_text()
client = (ROOT / 'modules/weather/client.lua').read_text()
server = (ROOT / 'modules/weather/server.lua').read_text()

assert "modules/weather/cd_easytime/dt_client.lua" in manifest
assert "modules/weather/cd_easytime/dt_server.lua" in manifest
assert "'cd_easytime'" in client
assert "'cd_easytime'" in server
assert "{'Renewed-Weathersync','cd_easytime','qb-weathersync'}" in client
assert "{'Renewed-Weathersync','cd_easytime','qb-weathersync'}" in server
assert (ROOT / 'modules/weather/cd_easytime/dt_client.lua').exists()
assert (ROOT / 'modules/weather/cd_easytime/dt_server.lua').exists()

from harness import load_manifest
for server_side in [False, True]:
    lua, _ = load_manifest(server_side, ['cd_easytime', 'qb-weathersync'])
    lua.execute('''
      function GetClockHours() return 15 end
      function GetClockMinutes() return 20 end
      function GetClockSeconds() return 25 end
      weatherData={weather='rain',hours='8',mins='7',blackout=true}
      exports.cd_easytime={GetAllData=function() return weatherData end,
        GetWeather=function() return 'thunder' end}
      assert(DT.Weather.Name()=='cd_easytime')
      assert(DT.Weather.GetCurrent()=='RAIN')
      local time=DT.Weather.GetTime();assert(time.hour==8 and time.minute==7)
      local data=DT.Weather.GetData();data.weather='CLEAR'
      assert(weatherData.weather=='rain')
      exports.cd_easytime.GetAllData=function() error('legacy version') end
      assert(DT.Weather.GetCurrent()=='THUNDER')
      assert(DT.Weather.GetData()==nil)
      DTConfig.Adapters.weather='easytime';assert(DT.Weather.Name()=='cd_easytime')
      DTConfig.Adapters.weather='CD_EASYTIME';assert(DT.Weather.Name()=='cd_easytime')
    ''')
    if server_side:
        lua.execute('assert(DT.Weather.GetTime()==nil)')
    else:
        lua.execute('local t=DT.Weather.GetTime();assert(t.hour==15 and t.minute==20 and t.second==25)')
print('Easytime client/server auto priority, exports, normalization, aliases, snapshots and legacy fallback PASS')
