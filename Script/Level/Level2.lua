local LevelManager = require('LevelManager').LevelManager

return {
    onRightWallTrigger = function(selfEntity, otherEntity)
        if otherEntity:getName_const() == 'player' then
            LevelManager.static.getInstance():requestLoadLevel('Level1')
        end
    end
}