
local MUtils = require('MUtils')
local MOD_BaseComponent = require("BaseComponent").BaseComponent
local MOD_DrawableCMP = require('Component.DrawableCMP').DrawableCMP

--- Animation组件负责播放Sprite动画
--- @class AnimationCMP : DrawableCMP
--- @field _sheet any
--- @field _frames table
--- @field _curFrameIdx number
--- @field _frameRate number
--- @field _frameCount number
--- @field _invFrameRate number
--- @field _timeForNextFrame number
--- @field _maxBounding any
--- @field _frameWidth number
--- @field _frameHeight number
local AnimationCMP = setmetatable({}, MOD_DrawableCMP)
AnimationCMP.__index = AnimationCMP
AnimationCMP.ComponentTypeName = "AnimationCMP"
AnimationCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(AnimationCMP.ComponentTypeName)

--- cst, 构造Animation组件
--- 这个组件负责播放Sprite动画
--- @param image any 包含序列帧的图片
--- @param topLeftX number 帧的左上角X pix
--- @param topLeftY number 帧的左上角Y pix
--- @param bottomRightX number 帧的右下角X pix
--- @param bottomRightY number 帧的右下角Y pix
--- @param frameWidth number 一帧的宽度pix
--- @param frameHeight number 一帧的高度pix
--- @param specifiedFrameCount number|nil 指定从image中提取多少帧[opt]
function AnimationCMP:new(image, topLeftX, topLeftY, bottomRightX, bottomRightY, frameWidth, frameHeight, specifiedFrameCount)
    local iSPecifiedFrameCount = specifiedFrameCount or 0
    assert(frameWidth > 0, 'Frame width should greator than ZERO')
    assert(frameHeight > 0, 'Frame height should greator than ZERO')
    local instance = setmetatable(MOD_DrawableCMP.new(self, AnimationCMP.ComponentTypeName), self)
    instance._sheet = image
    instance._frames = {} -- 当前存储的帧数浪
    instance._curFrameIdx = 1 -- 当前正在播放的帧下标(Lua的下标从1开始)
    instance._frameRate = 12 -- 动画帧率12fps
    instance._invFrameRate = 1.0 / instance._frameRate -- 1.0 / frameRate
    instance._timeForNextFrame = instance._invFrameRate -- 切换到下一帧还需要多长时间
    instance._frameWidth = frameWidth
    instance._frameHeight = frameHeight

    local rangeWidth = bottomRightX - topLeftX
    local rangeHeight = bottomRightY - topLeftY
    if iSPecifiedFrameCount == 0 then
        -- 没有制定帧数量，认为整个给定的范围都是有效帧
        local warningFrameSettings = false
        warningFrameSettings = warningFrameSettings or not MUtils.divlib.isDivisible(rangeWidth, frameWidth)
        warningFrameSettings = warningFrameSettings or not MUtils.divlib.isDivisible(rangeHeight, frameHeight)
        if warningFrameSettings then
            print(string.format('Current frame range setting is not aligned! '))
        end
        local horizenFrameCount = math.floor(rangeWidth / frameWidth)
        local verticalFrameCount = math.floor(rangeHeight / frameHeight)
        instance._frameCount = horizenFrameCount * verticalFrameCount
    else
        instance._frameCount = iSPecifiedFrameCount
    end

    local accFrameCount = 0
    for y = 0, rangeHeight, frameHeight do
        for x = 0, rangeWidth, frameWidth do
            local quad = love.graphics.newQuad(x + topLeftX, y + topLeftY, frameWidth, frameHeight, instance._sheet)
            table.insert(instance._frames, quad)
            accFrameCount = accFrameCount + 1
            if accFrameCount >= instance._frameCount then
                break
            end
        end
        if accFrameCount >= instance._frameCount then
            break
        end
    end

    return instance
end

--- 返回组件的最大包围盒
--- @return any 组件的最大包围盒
function AnimationCMP:getMaxBounding()
    return self._maxBounding
end

---当前组件允许发起绘制
---@param transform love.Transform
---@return nil
function AnimationCMP:draw(transform)
    -- 以下的selfTranslate和selfScale，相当于认为图片的帧就是1m x 1m的大小
    local selfTranslate = love.math.newTransform(-0.5, -0.5)
    local selfScale = love.math.newTransform(0, 0, 0, 1 / self._frameWidth, 1 / self._frameHeight)
    
    local selfTransform = selfTranslate:apply(transform):apply(selfScale)
    love.graphics.draw(self._sheet, self._frames[self._curFrameIdx], selfTransform)
end

--- 更新方法，用于更新当前的帧
--- @param deltaTime number 两次update之间的时间差(second)
--- @return nil
function AnimationCMP:update(deltaTime)
    local TimeManager = require('TimeManager').TimeManager.static.getInstance()
    local dt = TimeManager:getDeltaTime(deltaTime, self:getEntity())

    local newTimeForNextFrame = self._timeForNextFrame - dt
    if newTimeForNextFrame < 0 then
        self._curFrameIdx = (self._curFrameIdx % self._frameCount) + 1
        self._timeForNextFrame = self._invFrameRate + newTimeForNextFrame
    else
        self._timeForNextFrame = newTimeForNextFrame
    end
end


--- 实现时间回溯接口
--- @return table 回溯数据
function AnimationCMP:getRewindState_const()
    assert(self._curFrameIdx >= 1 and self._curFrameIdx <= self._frameCount, "Invalid curFrameIdx in AnimationCMP getRewindState_const!")
    return {
        curFrameIdx = self._curFrameIdx,
        timeForNextFrame = self._timeForNextFrame
    }
end

--- 从回溯数据中恢复状态
--- @param state table 回溯数据
--- @return nil
function AnimationCMP:restoreFromRewindState(state)
    self._curFrameIdx = state.curFrameIdx
    self._timeForNextFrame = state.timeForNextFrame
end


function AnimationCMP:lerpRewindState(stateA, stateB, t)
    if not stateA or not stateB then return end

    if stateA.curFrameIdx == stateB.curFrameIdx then
        -- 同一帧，直接线性插值时间
        self._curFrameIdx = stateA.curFrameIdx
        self._timeForNextFrame = stateA.timeForNextFrame + (stateB.timeForNextFrame - stateA.timeForNextFrame) * t
    else
        -- 不同帧，计算时间差
        -- 计算两个state之间的时间差
        assert(self._invFrameRate >= stateB.timeForNextFrame and self._invFrameRate >= stateA.timeForNextFrame, "Invalid frame rate settings in AnimationCMP lerpRewindState!")
        local timeBetweenStates = (self._invFrameRate - stateB.timeForNextFrame) + stateA.timeForNextFrame
        assert(timeBetweenStates >= 0 and timeBetweenStates <= self._invFrameRate, "Invalid time between states in AnimationCMP lerpRewindState!")
        if timeBetweenStates * t >= stateA.timeForNextFrame then
            -- 已经切换到下一帧
            self._curFrameIdx = stateB.curFrameIdx
            self._timeForNextFrame = self._invFrameRate - (timeBetweenStates * t - stateA.timeForNextFrame)
        else
            -- 仍然在当前帧
            self._curFrameIdx = stateA.curFrameIdx
            self._timeForNextFrame = stateA.timeForNextFrame - timeBetweenStates * t
        end
    end

    assert(self._curFrameIdx >= 1 and self._curFrameIdx <= self._frameCount, "Invalid curFrameIdx in AnimationCMP lerpRewindState!")    

end

return {
    AnimationCMP = AnimationCMP,
}

