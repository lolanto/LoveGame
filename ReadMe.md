# 关于
* 一次AI协助编程的实践
* 一次ECS模式的实践
* 一次Gameplay开发的实践

## ECS
Entity：负责挂接组件
Component: 指定概念与之相关的数据的集合，不应该拥有“行为”
System: 对多个指定概念及其相关数据的处理

## 组件

### BaseComponent
组件对象的基类，继承它只是说明这个类型对象属于组件类，同时可以查询自己的组件类型ID以及组件名字。没有强制要求指定的行为。

### AnimationCMP
负责播放动画的组件？准确说是Sprite动画的组件。

### CameraCMP
镜头组件。用来记录镜头相关的参数，这些参数最后会被用来计算视口变换矩阵。

### MainCharacterControllerCMP
主角控制器组件。这个组件将用户的输入转变成主角相关的一系列Gameplay行动指令，e.g. 移动、Gameplay相关的交互。

### MovementCMP
移动组件。记录移动属性，比方说移动速度。这些数据最后参与到更新TransformCMP组件的属性中去，一起更新实体的位置信息。

### TransformCMP
变换组件。记录实体的变换属性，决定了实体在整个世界中的位置，大小缩放以及旋转角度。

## 系统

## 其它

