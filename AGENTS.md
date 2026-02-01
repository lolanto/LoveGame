# AGENTS.md - AI 助手上下文指南

此文件旨在帮助 AI 助手（GitHub Copilot 等）理解本项目的架构、规范和最佳实践。请在生成代码时参考此文件，以确保代码风格一致且符合项目架构。

## 1. 项目概况 (Project Overview)
- **引擎**: Love2D (LÖVE)
- **语言**: Lua (LuaJIT)
- **核心架构**: 自研 ECS (Entity-Component-System)
- **坐标系**: 标准 Love2D 坐标系 (原点左上角，X 向右，Y 向下)，另外，游戏逻辑中涉及的单位都是国际标准单位。比如描述空间长度单位应该使用米

## 2. 代码风格规范 (Coding Standards)

### 命名约定
- **类/模块文件**: PascalCase (大驼峰)，与文件名一致 (如 `BaseSystem.lua`, `PlayerController.lua`)。
- **变量/函数**: camelCase (小驼峰) (如 `local currentSpeed`, `function updatePosition()`)。
- **私有成员**: 建议以 `_` 开头 (如 `self._internalState`)。
- **常量**: SCREAMING_SNAKE_CASE (如 `MAX_VELOCITY`)。
- **字符串声明**: 应该使用单引号\'\'定义字符串

### Lua 最佳实践
- **局部变量**: 始终优先使用 `local` 声明变量。
- **模块化**: 每个文件应返回一个 Table 或 Class。
- **面向对象**: 使用项目约定的 Class 模拟方式 (参考 `BaseComponent` 或 `BaseSystem`)。

### 类声明
当需要声明某个类型时，需要遵守以下规则：
```lua
--- @class SampleClass
--- @field MemberVariable VariableType
--- @field MemberFunction 
--- more filed desc....
local SampleClass = {}
SampleClass.__index = SampleClass
SampleClass.static = {} --- 类的静态成员变量或者成员函数需要定义在这个表下

function SampleClass:new()
    local instance = setmetatable({}, self)
    --- existing code...
    return instance
end

--- existing code...

return {
    SampleClass = SampleClass
}
```
#### 单例类声明
当需要声明单例类时，除了遵守一般类的声明以外，还需要符合下述代码规范
```lua
--- @class SampleClass
--- @field MemberVariable VariableType
--- @field MemberFunction 
--- more filed desc....
local SingletonClass = {}
SingletonClass.__index = SingletonClass
SingletonClass.static = {}
SingletonClass.static.instance = nil

SingletonClass.static.getInstance = function()
    if SingletonClass.static.instance == nil then
        SingletonClass.static.instance = SingletonClass:new()
    end
    return SingletonClass.static.instance
end

function SingletonClass:new()
    assert(SingletonClass.static.instance == nil, 'SingletonClass can only have one instance!')
    --- existing code...
end
```

## 3. ECS 架构指南 (ECS Guidelines)

本项目严格遵循 ECS 模式，请生成代码时遵守以下规则：

### Component (组件)
- **路径**: `Script/Component/` 及其子目录。
- **职责**: **只包含纯数据**，严禁包含业务逻辑。
- **基类**: 必须继承自 `BaseComponent`。
- **代码模板**:
```lua
local MOD_BaseComponent = require("BaseComponent").BaseComponent
local ExampleCMP = setmetatable({}, {__index = MOD_BaseComponent})
ExampleCMP.__index = ExampleCMP
ExampleCMP.ComponentTypeName = 'ExampleCMP'
ExampleCMP.ComponentTypeID = MOD_BaseComponent.RegisterType(ExampleCMP.ComponentTypeName)

function ExampleCMP:new(params)
    -- 定义组件数据
end

-- 定义组件提供的属性查询以及修改接口

return {
    ExampleCMP = ExampleCMP,
}
```

### System (系统)
- **路径**: `Script/System/` 及其子目录。
- **职责**: 处理特定逻辑，每一帧更新或渲染拥有特定组件集的实体。
- **基类**: 必须继承自 `BaseSystem`。
- **主要方法**: `new`, `tick`, `preCollect`, `collect`。
- **代码模板**:
```lua
local MOD_BaseSystem = require("BaseSystem").BaseSystem
local ExampleSysUsedCMP = require('Component.ExampleSysUsedCMP').ExampleSysUsedCMP

local ExampleSys = setmetatable({}, MOD_BaseSystem)
ExampleSys.__index = ExampleSys
ExampleSys.SystemTypeName = 'ExampleSys'

function ExampleSys:new()
    local instance = setmetatable(MOD_BaseSystem.new(self, ExampleSys.SystemTypeName), self)
    local ComponentRequirementDesc = require('BaseSystem').ComponentRequirementDesc
    instance:addComponentRequirement(ExampleSysUsedCMP.ComponentTypeID, ComponentRequirementDesc:new(true, false))
    --- 该系统需要关联的更多组件类型
    return instance
end

function ExampleSys:tick(deltaTime)
    --- 每一帧更新执行的代码
end

return {
    ExampleSys = ExampleSys,
}
```

### Entity (实体)
- **概念**: 实体仅仅是 ID 和组件的容器。
- **创建**: 通常在 `Levels/` 下的关卡脚本中组装。也可能会在根据运行时逻辑动态创建和组装

## 4. 目录结构说明 (Directory Map)
- `Levels/`: 关卡定义脚本，负责初始化场景关联的实体。
- `Script/`: 核心代码库。
    - `Component/`: 组件定义 (数据)。
    - `System/`: 系统逻辑 (行为)。
    - `Utils/`: 通用工具函数。
    - `Config.lua`: 全局配置。
- `Resources`: 包含非代码的资源文件，如纹理贴图
- `Engine`: 引擎二进制目录
- `Log`: 项目开发日志
- `main.lua`: 程序入口，负责加载 World，启动主循环。

## 5. 常用工具与库 (Utils & Libs)
- **日志**: 使用 `Script/Logger.lua` ，避免使用裸 `print`。
    - 不同的日志等级可以使用诸如`MUtils.Log`，`MUtils.Warning`等方式。
    - 某一管理器(Manager)或者系统(System)及其关联组件(Component)需要打印日志前，都需要在文件开头声明日志类型，以及在管理器或者系统初始化时注册日志类型。示例代码：
```lua
--- 文件开头日志类型声明
local MUtils = require('MUtils')
local LOG_MODULE = 'NameOfLogModule'

--- 管理器或者系统初始化function内
function xxx:new()
    --- existing code...
    MUtils.RegisterModule(LOG_MODULE)
    --- existing code...
end

function xxx:sampleFunc()
    --- existing code...
    --- 需要打印日志时
    MUtils.Log(LOG_MODULE, 'concrete log')
end
```
- **数学**: 尽量使用Lua以及Love2D 自带数学库。
- **资源路径**: 引用资源时使用相对于项目根目录的路径。

## 6. 注意事项 (Critical Notes)
- **性能**: 避免在 `Update` 循环中频繁创建临时 Table (GC 压力)。
- **Require 路径**: 使用点号 `.` 分隔路径 (如 `require("Component.TransformCMP")`)。搜索路径默认带上了`Script`以及`Script.utils`
- **全局环境**: 严禁污染全局 `_G`，除非是架构层面的单例。
