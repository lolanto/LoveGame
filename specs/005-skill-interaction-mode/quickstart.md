# Quickstart: Skill Interaction Mode

## Overview
This feature allows players to pause time and precisely aim skills (e.g., Black Hole, Teleport). While in this mode, game physics stops, but the specific skill logic continues to update and render indicators.

## How to Integrate a New Skill

### 1. In Your System (e.g., `MySkillSys.lua`)

1.  **Require the Manager**:
    ```lua
    local InteractionManager = require('InteractionManager').InteractionManager
    ```

2.  **Request Start**:
    Call `InteractionManager:requestStart(self)` when the trigger key is pressed.
    ```lua
    function MySkillSys:processUserInput(controller)
        if controller:isKeyPressed('T') then
            InteractionManager:requestStart(self, 5.0) -- 5s timeout
        end
    end
    ```

3.  **Handle Updates**:
    While `InteractionManager:isActive()` is true, standard physics logic is paused. Your system needs to handle the aiming logic.
    *   **Listen for Event**: Subscribe `Event_InteractionStarted` to initialize indicator.
    *   **Tick**: In `tick(dt)`, check `InteractionManager:isActive()`. If true, update your indicator using `dt` (Real Time). Be aware `TimeManager` scale is 0.

4.  **End Interaction**:
    Call `InteractionManager:requestEnd("Manual")` when the trigger is released.
    ```lua
    if controller:isKeyReleased('T') then
        InteractionManager:requestEnd("Manual")
    end
    ```

5.  **Execute Skill**:
    Subscribe to `Event_InteractionEnded`. Check if the initiator is `self`. If so, spawn the projectile/effect at the aimed location.

## Example: Debug Skill

Use the `TestSkillSys.lua` (to be created) to verify.
1.  Run the game.
2.  Hold `K`.
3.  Observe physics pause (gravity stops).
4.  Observe red circle indicator following mouse.
5.  Release `K`.
6.  Physics resume.

## Troubleshooting

*   **Physics not pausing?** Ensure `TimeManager:setTimeScale(0)` is called (Manager handles this).
*   **Indicator frozen?** Ensure you are updating the indicator position manually or using `TimeScaleException` on the indicator entity.
*   **Input stuck?** Ensure `requestEnd` is called on key release.

