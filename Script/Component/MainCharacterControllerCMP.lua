
local MOD_BaseComponent = require('BaseComponent')

---@class MainCharacterControllerCMP : BaseComponent
local MainCharacterControllerCMP = setmetatable({}, MOD_BaseComponent)
MainCharacterControllerCMP.__index = MainCharacterControllerCMP
MainCharacterControllerCMP.ComponentTypeName = "MainCharacterControllerCMP"
MainCharacterControllerCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(MainCharacterControllerCMP.ComponentTypeName)

function MainCharacterControllerCMP:new()
    local instance = setmetatable(MOD_BaseComponent.new(self, MainCharacterControllerCMP.ComponentTypeName), self)
    return instance
end

function MainCharacterControllerCMP:()
    
end