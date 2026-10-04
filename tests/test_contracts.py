"""Cfx simulation only. Run: python -m pip install lupa; python tests/test_contracts.py."""
from harness import root, runtime, load_manifest
from lupa.lua54 import LuaRuntime
import re

compiler=LuaRuntime().eval('function(source,name) local chunk,error=load(source,name);return error end')
for path in root.rglob('*.lua'):
    error=compiler(re.sub(r'`[^`]+`','42',path.read_text()),str(path))
    assert error is None,(path,error)
print('Lua syntax:',len(list(root.rglob('*.lua'))),'PASS')

catalog_runtime=runtime()
catalog=catalog_runtime.globals().DTEcosystemCatalog
profiles=[(category,p) for category,c in catalog.items() for _,p in c.providers.items()]
assert len(profiles)==153
passes=0
for server in (False,True):
    lua,count=load_manifest(server,[p.resource for _,p in profiles])
    for category,profile in profiles:
        if not profile['server' if server else 'client']:continue
        result=lua.globals().DT.Ecosystem.Get(category,profile.resource)
        api,reason=result if isinstance(result,tuple) else (result,None)
        assert api is not None,(category,profile.resource,server,reason)
        assert api.GetResourceName()==profile.resource
        passes+=1
    print('Manifest',('server' if server else 'client'),count,'scripts PASS')
print('Provider/side initialization:',passes,'PASS')

lua,_=load_manifest(False,['okokGasStation','okokGarage','lation_ui','okokNotify','okokTextUI'])
lua.execute('''
    local fuel=DT.Ecosystem.Get('fuel','okokGasStation')
    fuel.SetFuel(12,120);local c=calls[#calls];assert(c.method=='SetFuel' and c.args[2]==12 and c.args[3]==100)
    events={};TriggerServerEvent=function(...) events[#events+1]={...} end
    DT.Ecosystem.Get('vehiclekey','okokGarage').GiveKeys(12,'PLATE')
    assert(events[1][1]=='okokGarage:GiveKeys' and events[1][2]=='PLATE')
    DT.Ecosystem.Get('notify','okokNotify').SendNotification('TITLE','BODY','success',4500)
    c=calls[#calls];assert(c.resource=='okokNotify' and c.method=='Alert')
    DT.Ecosystem.Get('helptext','okokTextUI').ShowHelpText('Hello','left')
    c=calls[#calls];assert(c.method=='Open' and c.args[2]=='Hello')
    assert(not DT.Ecosystem.Supports('vehiclekey','RemoveKeys','cd_garage'))
    local missing,reason=DT.Ecosystem.Require('../source.lua');assert(missing==nil and reason=='invalid_module_name')
    local ui=exports.lation_ui
    exports.lation_ui=ui
    ui.progressBar=function(_,data) progressPayload=data;return true end
    ui.alert=function(_,data) alertPayload=data;return 'confirm' end
    ui.input=function(_,data) inputPayload=data;return {'Anaqi',7} end
    ui.registerListMenu=function(_,data,callback) listPayload=data;listCallback=callback end
    ui.showListMenu=function(_,id,start) listId=id end
    ui.getOpenListMenu=function() return listId end
    ui.hideListMenu=function() listId=nil end
    ui.setListMenuOptions=function(_,id,options,index) listReplacement=options end
    DTConfig.Adapters.ui='lation_ui'
    assert(DT.Progress({duration=4500,steps={{description='First'},{description='Second'}}}))
    assert(#progressPayload.steps==2 and progressPayload.duration==4500)
    assert(DT.Alert.Await({title='Confirm',description='Proceed?',callouts={{description='Check'}}})=='confirm')
    assert(alertPayload.header=='Confirm' and #alertPayload.callouts==1)
    local answer=DT.Input.Await({title='Profile',fields={{name='name',type='text'},{name='age',type='number'}}})
    assert(answer.name=='Anaqi' and answer.age==7)
    local selected=0
    assert(DT.ListMenu.Open({id='settings',options={{label='Radio',values={'A','B'},close=false}}},function(index,value) assert(index==1 and value==2);selected=selected+1 end)=='settings')
    assert(listPayload.options[1].values[2]=='B');listCallback(1,2,{},false);assert(selected==1)
    DT.ListMenu.SetOptions('settings',{{label='Updated',close=false}});assert(listReplacement[1].label=='Updated')
    assert(DT.ListMenu.GetOpen()=='settings' and DT.ListMenu.Close())
    DTConfig.Ecosystem.providers.menu='ox_lib';assert(DT.Ecosystem.Provider('menu')=='unavailable')
    DTConfig.Ecosystem.providers.menu='lation_ui';assert(DT.Ecosystem.Provider('menu')=='lation_ui')
    local exits,choice=0,0
    DT.Menu.Open({provider='native',items={{label='Keep open',close=false}},onExit=function() exits=exits+1 end})
    handlers.menuSelect({index=1},function() end);DT.Menu.Close();assert(exits==1)
    DT.Menu.Open({provider='native',items={{label='First',onSelect=function()
        DT.Menu.Open({provider='native',items={{label='Second',onSelect=function() choice=2 end}}})
    end}}})
    handlers.menuSelect({index=1},function() end);handlers.menuSelect({index=1},function() end);assert(choice==2)
''')
print('Lation and okok UI/fuel/key routing PASS')

lua,_=load_manifest(True,['okokBanking','ox_inventory','one_inventory','qs-inventory'])
lua.execute('''
    local banking=DT.Ecosystem.Get('banking','okokBanking')
    banking.AddAccountMoney('police',20,'reason');local c=calls[#calls]
    assert(c.method=='AddMoney' and c.args[2]=='police' and c.args[3]==20)
    assert(banking.RemoveAccountMoney('police',-1)==false)
    local inv=DT.Ecosystem.Get('inventory','ox_inventory');local metadata={serial='ABC'}
    inv.AddItem(10,'water',2,4,metadata);c=calls[#calls]
    assert(c.method=='AddItem' and c.args[2]==10 and c.args[5]==metadata and c.args[6]==4)
    inv=DT.Ecosystem.Get('inventory','qs-inventory');inv.AddItem(10,'water',2,4,metadata);c=calls[#calls]
    assert(c.args[5]==4 and c.args[6]==metadata)
    assert(inv.AddItem(10,'water',-1)==false)
    local skills=DT.Ecosystem.Get('skills','native');skills.Create('mining',5,50,1)
    assert(skills.SetXP(10,'mining',100) and skills.GetSkillLevel(10,'mining')==3)
    assert(skills.RemoveXp(10,'mining',40) and skills.GetSkillLevel(10,'mining')==2)
    balance=100;delivery=false
    DT.Player.GetCoords=function() return vec3(0,0,0) end
    DT.Player.HasGroup=function() return true end
    DT.Player.GetMoney=function() return balance end
    DT.Player.RemoveMoney=function(_,_,value) balance=balance-value;return true end
    DT.Player.AddMoney=function(_,_,value) balance=balance+value;return true end
    DT.Inventory.CanCarry=function() return true end
    DT.Inventory.AddItem=function() return delivery end
    local shop=DT.Ecosystem.Get('shops','native')
    assert(shop.CreateShop('test',{{name='water',price=10,count=2}},vec3(0,0,0)))
    assert(shop.CompleteCheckout(10,'test','water',1,'cash')==false)
    assert(shop.OpenShop(10,'test'))
    local ok,reason=shop.CompleteCheckout(10,'test','water',1,'cash');assert(not ok and reason=='inventory_failed' and balance==100)
    delivery=true;assert(shop.CompleteCheckout(10,'test','water',2,'cash') and balance==80)
    assert(shop.CompleteCheckout(10,'test','water',1,'cash')==false)
    assert(shop.CompleteCheckout(10,'test','water',1.5,'cash')==false)
''')
print('Banking, inventory order, skills and shop refund/stock/session PASS')
manifest=(root/'fxmanifest.lua').read_text()
assert "fx_version 'cerulean'" in manifest
assert "dependency 'community_bridge'" not in manifest
assert (root/'LICENSE').is_file()
print('Standalone resource manifest and LICENSE PASS')
