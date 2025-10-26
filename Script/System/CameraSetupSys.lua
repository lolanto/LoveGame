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

--- 该模块负责根据镜头组件，设置当前的渲染配置
---@class CameraSetupSys : BaseSystem
local CameraSetupSys = setmetatable({}, MOD_BaseSystem)
CameraSetupSys.__index = CameraSetupSys
CameraSetupSys.SystemTypeName = "CameraSetupSys"


function CameraSetupSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, CameraSetupSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(require('Component.CameraCMP').CameraCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    instance:addComponentRequirement(require('Component.TransformCMP').TransformCMP.ComponentTypeID, ComponentRequirementDesc:new(true, true))
    return instance
end


--- 从Entity身上搜集CameraCMP和TransformCMP组件
--- 理论上只会收集一个摄像机组件
---@param entity Entity 目标Entity，将会从这个entity身上搜集组件
---@return nil
function CameraSetupSys:collect(entity)
    local lenOfCameraCmps = #self._collectedComponents['CameraCMP']
    local lenOfTransformCmps = #self._collectedComponents['TransformCMP']
    assert(lenOfCameraCmps == lenOfTransformCmps, string.format("The count of CameraCMP %d should be equal to the count of TransformCMP %d", lenOfCameraCmps, lenOfTransformCmps))
    -- 当且仅当lenOfCameraCmps ~= 1时，尝试从entity搜索组件
    while lenOfCameraCmps ~= 1 do
        local ignoreThisEntity = false
        local cameraCmp = nil
        local transformCmp = nil
        -- 搜索CameraCMP和TransformCMP
        if ignoreThisEntity == false then
            cameraCmp = entity:getComponent('CameraCMP')
            if cameraCmp == nil then
                ignoreThisEntity = true
            end
        end
        if ignoreThisEntity == false then
            transformCmp = entity:getComponent('TransformCMP')
            if transformCmp == nil then
                ignoreThisEntity = true
            end
        end
        if ignoreThisEntity then
            goto continue
        end

        -- 通过检查，收集组件
        table.insert(self._collectedComponents['CameraCMP'], cameraCmp)
        table.insert(self._collectedComponents['TransformCMP'], transformCmp)
        -- 更新计数
        lenOfCameraCmps = #self._collectedComponents['CameraCMP']
        lenOfTransformCmps = #self._collectedComponents['TransformCMP']
        
        ::continue::
    end
end

--- 设置摄像机实体
--- 这个方法会调用collect方法从entity身上收集组件
--- 假如明确哪个entity是摄像机，可以直接调用这个方法以跳过
function CameraSetupSys:setupCameraEntity(entity)
    assert(entity ~= nil, "The entity to setup should not be nil!")
    self:collect(entity)
end

--- tick
--- 根据Camera Entity的Transform组件以及摄像机组件，计算一个完整的摄像机变换矩阵
--- 并通过love.graphics.replaceTransform应用这个变换矩阵
---@param deltaTime number 距离上一帧的时间间隔，单位秒
function CameraSetupSys:tick(deltaTime)
    MOD_BaseSystem.tick(self, deltaTime)
    if #self._collectedComponents['CameraCMP'] == 1 then
        local renderEnvObj = require('RenderEnv').RenderEnv.getGlobalInstance()
        ---@type CameraCMP
        local cameraCmp = self._collectedComponents['CameraCMP'][1]
        ---@type TransformCMP
        local transformCmp = self._collectedComponents['TransformCMP'][1]

        renderEnvObj:setViewWidth(cameraCmp:getViewWidthMeters_const())

        local camProjTransform = cameraCmp:getProjectionTransform()
        --- 根据摄像机的位置偏移camPosX和camPosY，以及摄像机的投影矩阵
        --- 计算一个完整的摄像机变换矩阵
        local completeCamTransform = transformCmp:getWorldTransform_const():inverse()
        completeCamTransform = camProjTransform:apply(completeCamTransform)
        renderEnvObj:setCameraProj(completeCamTransform)
    end
end

return {
    CameraSetupSys = CameraSetupSys,
}
