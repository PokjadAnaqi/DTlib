const fs = require('node:fs'), vm = require('node:vm'), assert = require('node:assert/strict');
const ticks = new Map(), events = new Map(), emitted = [];
let nextTick = 0, now = 0, held = false, exits = 0, draws = 0, exists = true;
const noop = () => {};
const context = {
    setTick(fn) { const id = nextTick++; ticks.set(id, fn); return id; },
    clearTick(id) { assert(ticks.delete(id)); },
    on(name, fn) { events.set(name, fn); },
    RegisterCommand: noop, RegisterKeyMapping: noop,
    GetCurrentResourceName: () => 'DTlib', GetGameTimer: () => now,
    DoesEntityExist: () => exists, PlayerPedId: () => 1, PlayerId: () => 0,
    GetEntityMatrix: () => [[0,1,0],[1,0,0],[0,0,1],[0,0,0]],
    GetEntityCoords: () => [0,0,0], GetEntityRotation: () => [0,0,0], GetEntityHeading: () => 0,
    GetDisabledControlNormal: () => 0.5, GetControlNormal: () => 0.5,
    IsDisabledControlPressed: () => held, IsControlPressed: () => held,
    IsDisabledControlJustPressed: () => false,
    EnterCursorMode: noop, LeaveCursorMode: () => exits++,
    SetMouseCursorActiveThisFrame: noop, SetMouseCursorSprite: noop,
    SetEntityDrawOutline: noop, SetEntityMatrix: noop, ExecuteCommand: noop,
    DisableControlAction: noop, DisableAllControlActions: noop,
    SetPauseMenuActive: noop, DisablePlayerFiring: noop,
    IsPedInMeleeCombat: () => false, IsPedShooting: () => false, IsPedReloading: () => false,
    ClearPedSecondaryTask: noop, DrawGizmo: () => { draws++; return false; },
    emit: (...args) => emitted.push(args),
};
vm.createContext(context);
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname, '../modules/placement/dtlib/gizmo.js'), 'utf8'), context);
const frame = () => { for (const fn of [...ticks.values()]) fn(); };
const start = () => events.get('DTlib:gizmo:start')(1, 'test', {camera:'gameplay', outline:false, freezePlayer:false});
assert.equal(ticks.size, 0, 'no idle JS frame callback after resource start');
start(); assert.equal(ticks.size, 1); frame(); assert.equal(draws, 1);
start(); assert.equal(ticks.size, 1, 'busy start must not register another tick');
assert.equal(emitted.at(-1)[2].reason, 'busy');
events.get('DTlib:gizmo:confirm')('test'); frame();
assert.equal(ticks.size, 0); assert.equal(exits, 1);
start(); frame(); held = true;
events.get('DTlib:gizmo:cancel')('test'); now = 1000; frame();
assert.equal(ticks.size, 1, 'ESC guard stays active while key is held'); assert.equal(exits, 1);
held = false; now = 1100; frame(); assert.equal(ticks.size, 1);
now = 1300; frame(); assert.equal(ticks.size, 0); assert.equal(exits, 2);
start(); events.get('DTlib:gizmo:cancel')('test');
start(); assert.equal(ticks.size, 1, 'reopening during guard reuses one tick');
events.get('DTlib:gizmo:confirm')('test'); frame(); assert.equal(ticks.size, 0);
start(); exists = false; frame(); assert.equal(emitted.at(-1)[2].reason, 'entity_missing');
now += 400; frame(); assert.equal(ticks.size, 0);
exists = true; start(); events.get('onResourceStop')('other'); assert.equal(ticks.size, 1);
events.get('onResourceStop')('DTlib'); assert.equal(ticks.size, 0);
console.log('On-demand gizmo ticks: idle, active, busy, confirm, held ESC, reopen, entity loss and stop PASS');
