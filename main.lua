package.path = package.path .. ";./Script/?.lua;./Script/utils/?.lua;"
local lldebugger = nil
if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
    lldebugger = require("lldebugger")
    lldebugger.start()
    print('lldebugger started')
end


---@type Entity[]
local entities = {}
---@type table<string, BaseSystem>
local systems = {}
local userInteractController = {}

---@type Entity|nil
local mainCharacterEntity = nil
---@type Entity|nil
local mainCameraEntity = nil

---@type RenderEnv|nil
local renderEnv = nil

function love.load()
    renderEnv = require('RenderEnv').RenderEnv:new()
    require('RenderEnv').RenderEnv.setGlobalInstance(renderEnv)
    userInteractController = require('UserInteractController').UserInteractController:new()

    local MUtils = require('MUtils')
    MUtils.InitLogger()
    -- Register some default modules if needed
    MUtils.RegisterModule("Main", "INFO", "DEBUG")
    
    local MOD_Entity = require('Entity')

    systems['TransformUpdateSys'] = require('System.TransformUpdateSys').TransformUpdateSys:new()
    systems['MainCharacterInteractSys'] = require('System.MainCharacterInteractSys').MainCharacterInteractSys:new()
    systems['PatrolSys'] = require('System.Gameplay.PatrolSys').PatrolSys:new()
    systems['EntityMovementSys'] = require('System.EntityMovementSys').EntityMovementSys:new()
    systems['CameraSetupSys'] = require('System.CameraSetupSys').CameraSetupSys:new()
    systems['DisplaySys'] = require('System.DisplaySys').DisplaySys:new()
    systems['PhysicSys'] = require('System.PhysicSys').PhysicSys:new()
    systems['PhysicVisualizeSys'] = require('System.PhysicSys').PhysicVisualizeSys:new()
    systems['TriggerSys'] = require('System.Gameplay.TriggerSys').TriggerSys:new()
    systems['TriggerSys']:setPhysicSys(systems['PhysicSys'])
    systems['TimeRewindSys'] = require('System.Gameplay.TimeRewindSys').TimeRewindSys:new()

    local image = love.graphics.newImage("Resources/debug_characters.png")
    print(image)
    love.graphics.setBackgroundColor(255,255,255)

    local player = MOD_Entity:new('player')
    player:boundComponent(require('Component.DrawableComponents.AnimationCMP').AnimationCMP:new(image, 0, 0, 736, 32, 32, 32))
    player:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    player:boundComponent(require('Component.MainCharacterControllerCMP').MainCharacterControllerCMP:new())
    player:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    player:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    player:boundComponent(require('Component.PhysicCMP').PhysicCMP:new(
        systems['PhysicSys']:getWorld(),
        {
            shape = require('Component.PhysicCMP').Shape.static.Rectangle(1, 1, 0, 0, 0, 1),
            fixedRotation = true
        }
    ))
    player:boundComponent(require('Component.Gameplay.TriggerCMP').TriggerCMP:new())
    player:getComponent('TriggerCMP'):setCallback(function(selfEntity, otherEntity)
        local otherName = otherEntity:getName_const()
        if otherName == 'wallLeft' then
            print("日志：Player 触碰到了 wallLeft！")
        end
    end)

    table.insert(entities, player)
    player:setNeedRewind(true)

    local entityCam = MOD_Entity:new('camera')
    entityCam:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    entityCam:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entityCam:boundComponent(require('Component.DrawableComponents.DebugTileTexture').DebugTileTextureCMP:new())
    table.insert(entities, entityCam)
    player:boundChildEntity(entityCam)

    -- local entity2 = MOD_Entity:new('debug')
    -- entity2:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({255,0,0,255}, 1, 1))
    -- entity2:getComponent('DebugColorBlockCMP'):setLayer(-1) -- 设置这个组件的绘制层级为-1
    -- entity2:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    -- entity2:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    -- table.insert(entities, entity2)
    -- entity:boundChildEntity(entity2)

    local LevelManager = require('LevelManager')
    LevelManager.loadLevel('Levels.Level1', entities, systems)

    mainCharacterEntity = entity
    mainCameraEntity = entity
end

function preUpdate(deltaTime)
    userInteractController:preUpdate(deltaTime)
end

function postUpdate()
    userInteractController:postUpdate()
end

function love.update(deltaTime)
    preUpdate(deltaTime)
    
    local thisFrameEntities = {}
    local visitedEntities = {}
    local function traverseEntity(entity)
        if entity == nil or visitedEntities[entity] then
            return
        end
        visitedEntities[entity] = true
        table.insert(thisFrameEntities, entity)
        if entity.getChildren then
            local children = entity:getChildren()
            if children ~= nil then
                for i = 1, #children do
                    traverseEntity(children[i])
                end
            end
        end
    end

    local rootEntities = {}
    for i = 1, #entities do
        local entity = entities[i]
        if entity ~= nil then
            if mainCharacterEntity == nil and entity:hasComponent('MainCharacterControllerCMP') then
                mainCharacterEntity = entity
            end
            if mainCameraEntity == nil and entity:hasComponent('CameraCMP') then
                mainCameraEntity = entity
            end
            if entity.getParent == nil or entity:getParent() == nil then
                table.insert(rootEntities, entity)
            end
        end
    end

    for i = 1, #rootEntities do
        traverseEntity(rootEntities[i])
    end

    -- 更新用户输入，将UserInteractController传递给各个关键的组件
    -- todo 用户输入先交给UI逻辑过一遍

    -- 假如有主角实体，则将UserInteractController传递给主角控制组件
    if mainCharacterEntity ~= nil then
        ---@type BaseComponent|nil
        local mainCharCtrlCmp = mainCharacterEntity:getComponent('MainCharacterControllerCMP')
        if mainCharCtrlCmp ~= nil then
            ---@cast mainCharCtrlCmp MainCharacterControllerCMP
            mainCharCtrlCmp:update(deltaTime, userInteractController)
        end
    end

    systems['TimeRewindSys']:processUserInput(userInteractController)

    systems['TransformUpdateSys']:preCollect()
    systems['MainCharacterInteractSys']:preCollect()
    systems['PatrolSys']:preCollect()
    systems['EntityMovementSys']:preCollect()
    systems['CameraSetupSys']:preCollect()
    systems['DisplaySys']:preCollect()
    systems['PhysicSys']:preCollect()
    systems['PhysicVisualizeSys']:preCollect()
    systems['TimeRewindSys']:preCollect()
    systems['TriggerSys']:preCollect()
    
    for i = 1, #thisFrameEntities do
        local entity = thisFrameEntities[i]
        if entity ~= nil then
            systems['TransformUpdateSys']:collect(entity)
            systems['MainCharacterInteractSys']:collect(entity)
            systems['PatrolSys']:collect(entity)
            systems['EntityMovementSys']:collect(entity)
            systems['CameraSetupSys']:collect(entity)
            systems['DisplaySys']:collect(entity)
            systems['PhysicSys']:collect(entity)
            systems['PhysicVisualizeSys']:collect(entity)
            systems['TimeRewindSys']:collect(entity)
            systems['TriggerSys']:collect(entity)
        end
    end

    systems['TimeRewindSys']:tick(deltaTime)
    
    if systems['TimeRewindSys']:getIsRewinding() then
        -- 回溯模式：跳过正常的逻辑更新和物理模拟
        -- 仅更新变换和摄像机/显示系统
        
        -- 确保Transform Hierarchy正确计算
        systems['TransformUpdateSys']:tick(deltaTime)

        systems['TimeRewindSys']:postProcess()
        
    else
        systems['MainCharacterInteractSys']:tick(deltaTime)
        systems['PatrolSys']:tick(deltaTime)
        systems['EntityMovementSys']:tick(deltaTime)
        systems['TransformUpdateSys']:tick(deltaTime)

        systems['PhysicSys']:tick(deltaTime)
        systems['TransformUpdateSys']:tick(deltaTime)
        systems['TriggerSys']:tick(deltaTime)
    end
    
    ---@cast systems['CameraSetupSys'] CameraSetupSys
    systems['CameraSetupSys']:tick(deltaTime)
    systems['DisplaySys']:tick(deltaTime)

    postUpdate()
end

function love.draw()
    love.graphics.replaceTransform(renderEnv:getCameraProj())
    systems['DisplaySys']:draw()
    -- systems['PhysicVisualizeSys']:draw()
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
