# Love2D 游戏 ECS 架构关系图

## Component-System 关系图

```mermaid
graph TD
    %% 基础架构
    subgraph "基础架构"
        BaseComponent[BaseComponent<br/>基础组件类]
        BaseSystem[BaseSystem<br/>基础系统类]  
        Entity[Entity<br/>实体类]
    end
    
    %% 组件层
    subgraph "Components 组件层"
        AnimationCMP[AnimationCMP<br/>动画组件<br/>• 序列帧动画<br/>• 帧率控制<br/>• 纹理渲染]
        CameraCMP[CameraCMP<br/>摄像机组件<br/>• 视图缩放<br/>• 投影变换]
        MainCharacterControllerCMP[MainCharacterControllerCMP<br/>主角控制组件<br/>• 用户输入处理<br/>• 控制命令转换]
        MovementCMP[MovementCMP<br/>移动组件<br/>• 速度属性<br/>• X/Y轴速度]
        TransformCMP[TransformCMP<br/>变换组件<br/>• 位置坐标<br/>• 旋转角度<br/>• 缩放比例<br/>• 变换矩阵]
    end
    
    %% 系统层
    subgraph "Systems 系统层"
        DisplaySys[DisplaySys<br/>显示系统<br/>• 动画更新<br/>• 渲染绘制]
        CameraSetupSys[CameraSetupSys<br/>摄像机设置系统<br/>• 摄像机变换<br/>• 视图矩阵计算]
        EntityMovementSys[EntityMovementSys<br/>实体移动系统<br/>• 位置更新<br/>• 速度应用]
        MainCharacterInteractSys[MainCharacterInteractSys<br/>主角交互系统<br/>• 输入处理<br/>• 移动控制]
    end
    
    %% 外部输入
    UserInteractController[UserInteractController<br/>用户交互控制器<br/>• 键盘输入<br/>• 鼠标输入]
    
    %% 继承关系
    BaseComponent -.-> AnimationCMP
    BaseComponent -.-> CameraCMP  
    BaseComponent -.-> MainCharacterControllerCMP
    BaseComponent -.-> MovementCMP
    BaseComponent -.-> TransformCMP
    
    BaseSystem -.-> DisplaySys
    BaseSystem -.-> CameraSetupSys
    BaseSystem -.-> EntityMovementSys
    BaseSystem -.-> MainCharacterInteractSys
    
    %% 系统处理的组件关系
    DisplaySys -->|需要| AnimationCMP
    
    CameraSetupSys -->|需要| CameraCMP
    CameraSetupSys -->|需要| TransformCMP
    
    EntityMovementSys -->|需要| MovementCMP
    EntityMovementSys -->|需要| TransformCMP
    
    MainCharacterInteractSys -->|需要| MainCharacterControllerCMP
    MainCharacterInteractSys -->|需要| MovementCMP
    
    %% 输入处理流程
    UserInteractController -->|输入数据| MainCharacterControllerCMP
    
    %% Entity 绑定组件
    Entity -->|绑定| AnimationCMP
    Entity -->|绑定| CameraCMP
    Entity -->|绑定| MainCharacterControllerCMP
    Entity -->|绑定| MovementCMP
    Entity -->|绑定| TransformCMP

    %% 样式定义
    classDef componentClass fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#000
    classDef systemClass fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,color:#000
    classDef baseClass fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#000
    classDef inputClass fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    
    class AnimationCMP,CameraCMP,MainCharacterControllerCMP,MovementCMP,TransformCMP componentClass
    class DisplaySys,CameraSetupSys,EntityMovementSys,MainCharacterInteractSys systemClass
    class BaseComponent,BaseSystem,Entity baseClass
    class UserInteractController inputClass
```

## 系统工作流程

```mermaid
sequenceDiagram
    participant User as 用户输入
    participant UIC as UserInteractController
    participant MCCS as MainCharacterControllerCMP
    participant MCIS as MainCharacterInteractSys
    participant MC as MovementCMP
    participant EMS as EntityMovementSys
    participant TC as TransformCMP
    participant CSS as CameraSetupSys
    participant DS as DisplaySys
    participant AC as AnimationCMP

    User->>UIC: 键盘/鼠标输入
    UIC->>MCCS: 传递输入事件
    MCCS->>MCCS: 更新控制命令
    
    Note over MCIS,MC: 主角交互系统处理
    MCIS->>MCCS: 读取控制命令
    MCIS->>MC: 更新速度属性
    
    Note over EMS,TC: 实体移动系统处理
    EMS->>MC: 读取速度
    EMS->>TC: 更新位置
    
    Note over CSS: 摄像机系统处理
    CSS->>TC: 读取摄像机位置
    CSS->>CSS: 计算视图变换
    
    Note over DS,AC: 显示系统处理
    DS->>AC: 更新动画帧
    DS->>AC: 执行渲染
```

## 关键特性

### 1. ECS 架构模式
- **Entity**: 游戏对象的容器，可绑定多个组件
- **Component**: 纯数据结构，存储游戏对象的属性
- **System**: 处理逻辑，操作具有特定组件组合的实体

### 2. 组件职责分离
- **TransformCMP**: 处理所有空间变换（位置、旋转、缩放）
- **MovementCMP**: 管理移动速度
- **AnimationCMP**: 负责序列帧动画播放
- **CameraCMP**: 控制摄像机投影
- **MainCharacterControllerCMP**: 处理用户输入到游戏命令的转换

### 3. 系统依赖关系
- **DisplaySys**: 仅依赖 `AnimationCMP`
- **CameraSetupSys**: 需要 `CameraCMP` + `TransformCMP`
- **EntityMovementSys**: 需要 `MovementCMP` + `TransformCMP`
- **MainCharacterInteractSys**: 需要 `MainCharacterControllerCMP` + `MovementCMP`

### 4. 数据流向
1. 用户输入 → `UserInteractController` → `MainCharacterControllerCMP`
2. 控制命令 → `MainCharacterInteractSys` → `MovementCMP`
3. 速度数据 → `EntityMovementSys` → `TransformCMP`
4. 位置数据 → `CameraSetupSys` (摄像机跟随)
5. 动画数据 → `DisplaySys` → 屏幕渲染

这个架构设计实现了良好的模块化和可扩展性，每个组件和系统都有明确的职责，便于维护和扩展新功能。