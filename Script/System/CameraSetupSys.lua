--[[
    CameraSetupSys.lua
    描述：摄像机设置系统
    作用：根据摄像机组件，设置当前的渲染配置
    详细信息�?
        1. 该系统会收集拥有CameraCMP和TransformCMP组件的实�?
        2. 理论上只会收集一个摄像机组件
        3. 在tick阶段，根据摄像机实体的Transform组件以及摄像机组件，计算一个完整的摄像机变换矩�?
        4. 将计算的变换矩阵存入到RenderEnv对象中，供后续渲染使�?
--]]

local MOD_BaseSystem = require('BaseSystem').BaseSystem
local CameraCMP = require('Component.CameraCMP').CameraCMP
local TransformCMP = require('Component.TransformCMP').TransformCMP

--- 该模块负责根据镜头组件，设置当前的渲染配置
---@class CameraSetupSys : BaseSystem
local CameraSetupSys = setmetatable({}, MOD_BaseSystem)
CameraSetupSys.__index = CameraSetupSys
CameraSetupSys.SystemTypeName = "CameraSetupSys"


function CameraSetupSys:new(world)
    local instance = setmetatable(MOD_BaseSystem.new(self, CameraSetupSys.SystemTypeName, world), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(CameraCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:addComponentRequirement(TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:initView()
    return instance
end


--- 从Entity身上搜集CameraCMP和TransformCMP组件
--- 理论上只会收集一个摄像机组件
---@param deltaTime number
function CameraSetupSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)

    -- 使用ComponentsView获取所有Camera
    local view = self:getComponentsView()
    -- CHANGE: Use ComponentTypeName instead of ComponentTypeID
    local cameras = view._components[CameraCMP.ComponentTypeName]
    local transforms = view._components[TransformCMP.ComponentTypeName]

    if not cameras or not transforms then return end
    
    local count = view._count
    if count == 0 then return end

    -- 策略：使用第一个有效的Camera (First Active)
    for i = 1, count do
        local cameraCmp = cameras[i]
        local transformCmp = transforms[i]
        local entity = cameraCmp:getEntity_const()

        -- Check if enabled
        if entity and entity:isEnable_const() then
            self:updateCameraInfo(cameraCmp, transformCmp)
            return -- Stop after processing one
        end
    end
end

function CameraSetupSys:updateCameraInfo(cameraCmp, transformCmp)
    local renderEnvObj = require('RenderEnv').RenderEnv.getGlobalInstance()
    renderEnvObj:setViewWidth(cameraCmp:getViewWidthMeters_const())

    local camProjTransform = cameraCmp:getProjectionTransform_const()
    --- 计算一个完整的摄像机变换矩阵
    local camWorldTransform = transformCmp:getWorldTransform_const()
    
    -- NOTE: Creating a new transform or modifying existing one? 
    -- camWorldTransform is ReadOnly? .getMatrix() returns values.
    -- But logic below calls camWorldTransform:setMatrix()!
    -- If getMatrix returns values, then setMatrix on what object?
    -- camWorldTransform from getWorldTransform_const() might be a ReadOnly proxy which errors on setMatrix?
    -- Let's check TransformCMP.getWorldTransform_const().
    
    -- Optimization: Make a copy or use a temp transform to avoid modifying entity transform if implied.
    -- Actually the original code did:
    -- local camWorldTransform = transformCmp:getWorldTransform_const()
    -- camWorldTransform:setMatrix(...) 
    -- This implies camWorldTransform is NOT read-only or the user didn't use ReadOnly wrapper properly there, 
    -- OR `getWorldTransform_const` returns a new object/clone?
    -- If it returns internal object and we modify it, we mess up the entity transform!
    
    -- Let's replicate original logic but be careful.
    -- Warning: modifying world transform of entity to use 0 rotation for camera calculation?
    -- Logic: "将completeCamTransform拆分出来，将里面的旋转部分的变量替换为摄像机组件内的旋转变量" -> "Reconstruct camera matrix replacing rotation"
    
    -- Clone to be safe:
    local f_mat1_1, f_mat1_2, f_mat1_3, f_mat1_4
        , f_mat2_1, f_mat2_2, f_mat2_3, f_mat2_4
        , f_mat3_1, f_mat3_2, f_mat3_3, f_mat3_4
        , f_mat4_1, f_mat4_2, f_mat4_3, f_mat4_4 = camWorldTransform:getMatrix()
        
    local _worldPosX = f_mat1_4
    local _worldPosY = f_mat2_4
    local _worldScaleX = math.sqrt(f_mat1_1 * f_mat1_1 + f_mat2_1 * f_mat2_1)
    local _worldScaleY = math.sqrt(f_mat1_2 * f_mat1_2 + f_mat2_2 * f_mat2_2)
    -- local _worldRotate = math.atan2(f_mat2_1, f_mat1_1) -- Unused in reconstruction below?

    -- Create a new transform for calculation (Love2D Transform)
    local tempTransform = love.math.newTransform()
    tempTransform:setMatrix(
        _worldScaleX, 0, 0, _worldPosX,
        0,  _worldScaleY, 0, _worldPosY,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
    
    local completeCamTransform = tempTransform:inverse()
    completeCamTransform = camProjTransform:apply(completeCamTransform)
    renderEnvObj:setCameraProj(completeCamTransform)
end



return {
    CameraSetupSys = CameraSetupSys,
}
