local function providerName() local n=DT.UI.Name(); return n=='lation_ui' and 'lation_ui' or n=='ox_lib' and 'ox_lib' or 'native' end
local function A() return DT.UI.Adapter('helptext') end
local function normalize(text,options) local d; if type(text)=='table' then d=DTUtils.copy(text) else d=DTUtils.copy(options or {}); d.description=d.description or text or '' end; d.description=d.description or d.text or ''; d.position=d.position or DTConfig.UI.textUIPosition; d.options=type(d.options)=='table' and d.options or nil; return d end
function DT.TextUI.Show(text,options) local d=normalize(text,options); local a=A(); local ok,err=pcall(a.show,a,d); if ok then return true end; DT.Debug('TextUI provider failed, using native:',err); local n=DT.Modules.Get('helptext','native'); return n and n:show(d) or false end
function DT.TextUI.Hide() local a=A(); local ok=pcall(a.hide,a); if ok then return true end; local n=DT.Modules.Get('helptext','native'); return n and n:hide() or false end
function DT.TextUI.IsOpen() local a=A(); if a and a.isOpen then return a:isOpen() end; return false,nil end
exports('ShowTextUI',function(...) return DT.TextUI.Show(...) end); exports('HideTextUI',function(...) return DT.TextUI.Hide(...) end); exports('IsTextUIOpen',function(...) return DT.TextUI.IsOpen(...) end)
