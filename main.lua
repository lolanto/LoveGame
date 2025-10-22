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
    userInteractController = require('UserInteractController').UserInteractController:new()

    local MOD_Entity = require('Entity')

    systems['TransformUpdateSys'] = require('System.TransformUpdateSys').TransformUpdateSys:new()
    systems['MainCharacterInteractSys'] = require('System.MainCharacterInteractSys').MainCharacterInteractSys:new()
    systems['EntityMovementSys'] = require('System.EntityMovementSys').EntityMovementSys:new()
    systems['CameraSetupSys'] = require('System.CameraSetupSys').CameraSetupSys:new()
    systems['DisplaySys'] = require('System.DisplaySys').DisplaySys:new()

    local image = love.graphics.newImage("Resources/characters.png")
    print(image)
    love.graphics.setBackgroundColor(255,255,255)

    local entity = MOD_Entity:new('player')
    entity:boundComponent(require('Component.DrawableComponents.AnimationCMP').AnimationCMP:new(image, 0, 0, 736, 32, 32, 32))
    entity:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    entity:boundComponent(require('Component.MainCharacterControllerCMP').MainCharacterControllerCMP:new())
    entity:boundComponent(require('Component.MovementCMP').MovementCMP:new())
    entity:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    table.insert(entities, entity)

    local entityCam = MOD_Entity:new('camera')
    entityCam:boundComponent(require('Component.CameraCMP').CameraCMP:new())
    entityCam:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    table.insert(entities, entityCam)
    entity:boundChildEntity(entityCam)

    local entity2 = MOD_Entity:new('debug')
    entity2:boundComponent(require('Component.DrawableComponents.DebugColorBlockCMP').DebugColorBlockCMP:new({255,0,0,255}, 50, 50))
    entity2:getComponent('DebugColorBlockCMP'):setLayer(-1) -- 设置这个组件的绘制层级为-1
    entity2:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    table.insert(entities, entity2)

    local entityBackground = MOD_Entity:new('background')
    entityBackground:boundComponent(require('Component.DrawableComponents.StaticTextureCMP').StaticTextureCMP:new("Resources/debug_background_tile.png", {
        tileScale = 1.0,
        offsetX = 0,
        offsetY = 0,
        layer = -100, -- 设置这个组件的绘制层级为-100，确保在最底层
    }))
    entityBackground:boundComponent(require('Component.TransformCMP').TransformCMP:new())
    table.insert(entities, entityBackground)

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

    systems['TransformUpdateSys']:preCollect()
    systems['MainCharacterInteractSys']:preCollect()
    systems['EntityMovementSys']:preCollect()
    systems['CameraSetupSys']:preCollect()
    systems['DisplaySys']:preCollect()
    
    for i = 1, #thisFrameEntities do
        local entity = thisFrameEntities[i]
        if entity ~= nil then
            systems['TransformUpdateSys']:collect(entity)
            systems['MainCharacterInteractSys']:collect(entity)
            systems['EntityMovementSys']:collect(entity)
            systems['CameraSetupSys']:collect(entity)
            systems['DisplaySys']:collect(entity)
        end
    end

    systems['MainCharacterInteractSys']:tick(deltaTime)
    systems['EntityMovementSys']:tick(deltaTime)
    systems['TransformUpdateSys']:tick(deltaTime)
    ---@cast systems['CameraSetupSys'] CameraSetupSys
    systems['CameraSetupSys']:tick(deltaTime, renderEnv)
    systems['DisplaySys']:tick(deltaTime)

    postUpdate()
end

function love.draw()
    love.graphics.replaceTransform(renderEnv:getCameraProj())
    systems['DisplaySys']:draw()
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
