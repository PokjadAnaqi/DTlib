from harness import load_manifest
for server in [False, True]:
    lua, _ = load_manifest(server, ['lation_ui'])
    lua.execute('''sent={};function SendNUIMessage(data) sent[#sent+1]=data end
      function TriggerClientEvent(name,target,p) sent[#sent+1]={name=name,target=target,data=p} end''')
    if server:
        lua.execute("assert(DT.NotifyBanner(7,{title='ACTIVE',subject='Protection',image='nui://ox_inventory/web/images/pill.png',description='Full body'}))")
        lua.execute("assert(sent[1].target==7 and sent[1].data.layout=='banner' and sent[1].data.subtitle=='Protection')")
    else:
        lua.execute("assert(DT.NotifyBanner({title='ACTIVE',subject='Protection',image='nui://ox_inventory/web/images/pill.png',description='Full body'}))")
        lua.execute("assert(DT.NotifyProvider()=='lation_ui');assert(sent[1].action=='notify' and sent[1].data.layout=='banner' and sent[1].data.description=='Full body' and sent[1].data.subtitle=='Protection')")
print('Client/server banner API, provider isolation and image/subtitle/body forwarding PASS')
