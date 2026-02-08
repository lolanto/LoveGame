local LevelManager = require('LevelManager').LevelManager

return {
    onLeftWallTrigger = function(selfEntity, otherEntity)
        if otherEntity:getName_const() == 'player' then
            LevelManager.static.getInstance():requestLoadLevel('Level2')
        end
    end
}