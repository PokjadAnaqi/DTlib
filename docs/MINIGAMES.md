# DTlib Minigames

DTlib provides a unified minigame wrapper. Lation supplies Skill Check, Signal Breach, and Pattern Lock. From v1.0.21, ox_lib can be used as the fallback provider for Skill Check when Lation is unavailable.

## Requirements

`lation_ui` and `ox_lib` are optional. Start whichever provider you use before DTlib:

```cfg
ensure lation_ui # optional
ensure ox_lib    # optional ox Skill Check fallback
ensure DTlib
```

Configuration:

```cfg
DTConfig.Minigames.enabled = true
DTConfig.Minigames.provider = 'auto'
```

`provider` supports `auto`, `lation_ui`, `ox_lib`, or `disabled`. `auto` prefers Lation; if only ox_lib is available, Skill Check uses ox_lib while Signal Breach and Pattern Lock report unavailable.

```lua
print(DT.Minigame.Provider())         -- lation_ui / ox_lib / unavailable / disabled
print(DT.Minigame.Provider('skill'))  -- provider for Skill Check
print(DT.Minigame.Available('skill')) -- true / false
```

## Skill Check

```lua
local success = DT.Minigame.SkillCheck('Lockpick', 'easy', 'E')
```

Sequential difficulties and keys:

```lua
local success = DT.Minigame.SkillCheck(
    'Lockpick',
    {'easy', 'medium', 'hard'},
    {'E', 'E', 'E'},
    'compact'
)
```

Custom difficulty:

```lua
local success = DT.Minigame.SkillCheck({
    title = 'Precision Bypass',
    difficulty = { areaSize = 20, speedMultiplier = 1.5 },
    inputs = 'E',
    size = 'normal'
})
```

State/control:

```lua
DT.Minigame.SkillCheckActive()
DT.Minigame.CancelSkillCheck()
```

## Signal Breach

```lua
local success = DT.Minigame.SignalBreach('Hack Terminal', 'medium', 'E')
```

Progression options:

```lua
local success = DT.Minigame.SignalBreach('Bypass Firewall', 'hard', {'W', 'A', 'S', 'D'}, {
    speedIncrease = 0.08,
    windowDecrease = 2,
    failOnWrongKey = true,
    onNode = function(node, hit)
        print(('Node %s: %s'):format(node, hit and 'HIT' or 'MISS'))
    end
})
```

Custom difficulty:

```lua
local success = DT.Minigame.SignalBreach({
    title = 'Crack Encryption',
    difficulty = {
        nodes = 6,
        windowSize = 22,
        speed = 0.40
    },
    inputs = 'E',
    options = {
        speedIncrease = 0.06,
        windowDecrease = 2
    }
})
```

State/control:

```lua
DT.Minigame.SignalBreachActive()
DT.Minigame.CancelSignalBreach()
```

`onNode` is retained by the consumer resource and relayed through DTlib's local event bridge. It is never serialized as a Lua function across resources.

## Pattern Lock

```lua
local success = DT.Minigame.PatternLock('Bypass Panel', 'medium')
```

Multi-stage:

```lua
local success = DT.Minigame.PatternLock('Thermite Prep', {
    'easy', 'medium', 'hard'
})
```

Custom difficulty:

```lua
local success = DT.Minigame.PatternLock({
    title = 'Security Grid',
    difficulty = {
        gridSize = 4,
        sequenceLength = 6,
        showSpeed = 400,
        inputTimeout = 15
    }
})
```

State/control:

```lua
DT.Minigame.PatternLockActive()
DT.Minigame.CancelPatternLock()
```

## Compatibility aliases

```lua
DT.SkillCheck(...)
DT.SignalBreach(...)
DT.PatternLock(...)
```

Lower-camel aliases are also available (`DT.Minigame.skillCheck`, `signalBreach`, `patternLock`) for migration convenience. `DT.UI.SkillCheck`, `DT.UI.SignalBreach`, and `DT.UI.PatternLock` are provided as UI-namespace compatibility aliases.

## Behaviour when a provider is unavailable

The start functions return:

```lua
false, 'unavailable'
```

For Skill Check only, DTlib may fall back to ox_lib because it exposes compatible easy/medium/hard and custom difficulty semantics. Signal Breach and Pattern Lock remain Lation-only.
