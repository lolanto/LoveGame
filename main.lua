package.path = package.path .. ";./Script/?.lua;./Script/utils/?.lua;"
local lldebugger = nil
if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
    lldebugger = require("lldebugger")
    lldebugger.start()
    print('lldebugger started')
end


local userInteractController = {}

---@type RenderEnv|nil
local renderEnv = nil

function love.load()
    renderEnv = require('RenderEnv').RenderEnv:new()
    require('RenderEnv').RenderEnv.setGlobalInstance(renderEnv)
    
    local UserInteractController = require('UserInteractController').UserInteractController
    userInteractController = UserInteractController:new()

    local MUtils = require('MUtils')
    MUtils.InitLogger()
    MUtils.RegisterModule("Main", "INFO", "DEBUG")
    
    local MOD_Entity = require('Entity')
    local world = require('Script.World').getInstance()
    
    -- Register Systems
    local function reg(sys) world:registerSystem(sys) end
    
    local TransformUpdateSys = require('Script.System.TransformUpdateSys').TransformUpdateSys
    reg(TransformUpdateSys:new(world))
    
    local MainCharacterInteractSys = require('Script.System.MainCharacterInteractSys').MainCharacterInteractSys
    local mainCharSys = MainCharacterInteractSys:new(world)
    mainCharSys:setupUserInteractController(userInteractController)
    reg(mainCharSys)
    
    reg(require('Script.System.Gameplay.PatrolSys').PatrolSys:new(world))
    reg(require('Script.System.EntityMovementSys').EntityMovementSys:new(world))
    reg(require('Script.System.CameraSetupSys').CameraSetupSys:new(world))
    reg(require('Script.System.DisplaySys').DisplaySys:new(world))
    
    local PhysicSys = require('Script.System.PhysicSys').PhysicSys
    local physicSys = PhysicSys:new(world)
    reg(physicSys)
    reg(require('Script.System.PhysicSys').PhysicVisualizeSys:new(world))
    
    local TriggerSys = require('Script.System.Gameplay.TriggerSys').TriggerSys
    local triggerSys = TriggerSys:new(world)
    triggerSys:setPhysicSys(physicSys)
    reg(triggerSys)
    
    local BlackHoleSys = require('Script.System.Gameplay.BlackHoleSys').BlackHoleSys
    local blackHoleSys = BlackHoleSys:new(world)
    reg(blackHoleSys)
    
    local TimeRewindSys = require('Script.System.Gameplay.TimeRewindSys').TimeRewindSys
    local timeRewindSys = TimeRewindSys:new(world)
    timeRewindSys:setPhysicsWorld(physicSys:getPhysicsWorld()) 
    reg(timeRewindSys)
    
    local TimeDilationSys = require('Script.System.Gameplay.TimeDilationSys').TimeDilationSys
    local timeDilationSys = TimeDilationSys:new(world)
    timeDilationSys:setTimeRewindSys(timeRewindSys)
    reg(timeDilationSys)

    local image = love.graphics.newImage("Resources/debug_characters.png")
    love.graphics.setBackgroundColor(255,255,255)

    -- Setup Player
    local player = MOD_Entity:new('player')
    player:setEnable(true)
    player:setVisible(true)
    player:boundComponent(require('Component.DrawableComponents.AnimationCMP').AnimationCMP:new(image, 0, 0, 736, 32, 32, 32))
    player:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    player:boundComponent(require('Component.MainCharacterControllerCMP').MainCharacterControllerCMP:new())
    player:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    player:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    player:boundComponent(
        require('Component.PhysicCMP').PhysicCMP:new(
            physicSys:getWorld(),
            {
                shape = require('Component.PhysicCMP').Shape.static.Rectangle(1, 1, 0, 0, 0, 1),
                fixedRotation = true
            }
        )
    )
    player:boundComponent(require('Component.Gameplay.TriggerCMP').TriggerCMP:new())
    player:setNeedRewind(true)
    player:setTimeScaleException(true)
    
    world:addEntity(player)
    world:setMainCharacter(player)

    -- Setup Camera Entity (Child of Player)
    local entityCam = MOD_Entity:new('camera')
    entityCam:setEnable(true)
    entityCam:setVisible(true)
    entityCam:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    entityCam:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entityCam:boundComponent(require('Component.DrawableComponents.DebugTileTexture').DebugTileTextureCMP:new())
    player:boundChildEntity(entityCam)
    
    world:addEntity(entityCam)
    world:setMainCamera(entityCam)

    -- [Phase 4 Verification] Uncomment to run ECS Stress Tests
    -- require('Script.Tests.TestECSWorkflow').run()

    local LevelManager = require('LevelManager').LevelManager
    LevelManager.static.getInstance():requestLoadLevel('Level1')
end

function preUpdate(deltaTime)
    userInteractController:preUpdate(deltaTime)
end

function postUpdate()
    userInteractController:postUpdate()
end

function love.update(deltaTime)
    local world = require('Script.World').getInstance()
    
    require('MessageCenter').MessageCenter.static.getInstance():dispatch()

    preUpdate(deltaTime)
    
    require('LevelManager').LevelManager.static.getInstance():tick()
    
    world:update(deltaTime, userInteractController)

    postUpdate()
end

function love.draw()
    if renderEnv and renderEnv.getCameraProj then
        love.graphics.replaceTransform(renderEnv:getCameraProj())
    end
    
    local world = require('Script.World').getInstance()
    world:draw()
    
    -- require('Script.World').getInstance():getSystem('PhysicVisualizeSys'):draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    userInteractController:onMousePressed(x, y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    userInteractController:onMouseReleased(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
    -- debug helper: press 'b' to trigger debugger break if available
    if key == 'b' and lldebugger ~= nil and type(lldebugger["requestBreak"]) == 'function' then
        print('Invoking lldebugger.break()')
        lldebugger["requestBreak"]()
    else
        userInteractController:onKeyPressed(key)
    end
end

function love.keyreleased(key, scancode)
    if key == 'b' and lldebugger ~= nil and type(lldebugger["requestBreak"]) == 'function' then
    else
        userInteractController:onKeyReleased(key)
    end
end

local originalLoveHandler = love.errhand
function love.errorhandler(msg)
    if lldebugger ~= nil then
        error(msg, 2)
    else
        return originalLoveHandler(msg)
    end
end
