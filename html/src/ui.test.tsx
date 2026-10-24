// @vitest-environment jsdom
import React from 'react';
import {afterEach,beforeEach,expect,test,vi} from 'vitest';
import {act,cleanup,fireEvent,render,screen} from '@testing-library/react';
import {App} from './main';
const message=(action:string,data:any={})=>act(()=>window.dispatchEvent(new MessageEvent('message',{data:{action,data}})));
beforeEach(()=>{vi.stubGlobal('fetch',vi.fn(()=>Promise.resolve({})));window.DTNotifications={send:vi.fn(),remove:vi.fn(),clear:vi.fn()}});
afterEach(()=>{cleanup();vi.unstubAllGlobals()});
test('menu renders text safely, rejects scripts in image URLs and respects close/readOnly',()=>{
 render(<App/>);message('menu:open',{canClose:false,items:[{label:'<script>bad</script>',image:'javascript:alert(1)',readOnly:true}]});
 expect(screen.getByRole('button',{name:'<script>bad</script>'}).hasAttribute('disabled')).toBe(true);
 expect(document.querySelector('img')).toBeNull();fireEvent.keyDown(window,{key:'Escape'});expect(fetch).not.toHaveBeenCalled();
 message('menu:open',{items:[{label:'Open'}]});fireEvent.click(screen.getByRole('button',{name:'Open'}));
 expect(fetch).toHaveBeenCalledWith('https://DTlib/menuSelect',expect.objectContaining({body:'{"index":1}'}));
});
test('input values post to Lua and suspension removes overlays and clears notifications',()=>{
 render(<App/>);message('input:open',{title:'Form',fields:[{label:'Name',name:'name',default:'Delta'}]});
 fireEvent.submit(screen.getByRole('button',{name:'CONFIRM'}).closest('form')!);
 expect(fetch).toHaveBeenCalledWith('https://DTlib/inputSubmit',expect.objectContaining({body:'{"values":{"name":"Delta"}}'}));
 message('textui:show',{text:'Use terminal'});expect(screen.getByText('Use terminal')).toBeTruthy();
 message('ui:suspend');expect(screen.queryByText('Use terminal')).toBeNull();expect(screen.queryByText('Form')).toBeNull();expect(window.DTNotifications!.clear).toHaveBeenCalled();
});
