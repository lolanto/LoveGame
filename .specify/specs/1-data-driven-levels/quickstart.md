# Level Creation Guide

## 1. Create Data File
Create `Resources/Level/MyLevel.lua`.

```lua
return {
    name = "MyLevel",
    entities = {
        {
            name = "PlayerStart",
            components = {
                {
                    type = "TransformCMP",
                    properties = { worldPosition = {0, 0} }
                }
            }
        }
    }
}
```

## 2. Create Action Script (Optional)
If you need logic (triggers), create `Script/Level/MyLevel.lua`.

```lua
local LevelManager = require('LevelManager').LevelManager

return {
    onWinTrigger = function(self, other)
        if other:getName_const() == 'player' then
            LevelManager.static.getInstance():requestLoadLevel('Resources.Level.NextLevel')
        end
    end
}
```

## 3. Link Logic
In `Resources/Level/MyLevel.lua`, bind the trigger:

```lua
{
    type = "TriggerCMP",
    properties = {
        callback = "onWinTrigger"
    }
}
```
