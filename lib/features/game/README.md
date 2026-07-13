# 餐厅游戏基础结构

这套结构把地图、家具显示、家具摆放规则和关卡数据分开，方便逐项断点调试。

## 文件职责

- `models/restaurant_level_config.dart`：关卡与家具静态配置。新增关卡主要修改这里。
- `models/facility_placement.dart`：摆放成功/失败结果。
- `components/restaurant_map.dart`：等距坐标转换、墙体边界、碰撞和寻路。
- `components/restaurant_facility.dart`：家具图片、拖动、旋转和 Debug 绘制。
- `components/facility_placement_controller.dart`：统一判断越界、家具重叠，并刷新寻路障碍。
- `restaurant_level/restaurant_level1.dart`：第一关顾客、点餐、厨房和服务员流程。

## 调试家具摆放

1. 点击“摆放家具”进入编辑模式。
2. 青色框是当前选中家具的占地；红色框表示本次移动或旋转失败。
3. 控制台搜索 `[家具摆放]`，可以看到家具坐标、方向、占地和失败原因。
4. 家具占地不等于 PNG 尺寸。请在 `FacilityConfig.verticalFootprint` 和
   `horizontalFootprint` 中调整家具真正接触地面的宽高。

## 新增地图关卡

1. 在 Tiled 中复制现有关卡 TMX。
2. 保留 `collision` 对象层，并用四个长矩形表示上、下、左、右墙体。
3. 保留 `spawn` 对象层。家具出生点名称要与 `FacilityConfig.spawnName` 一致。
4. 在 `restaurant_level_config.dart` 新建一个 `RestaurantLevelConfig`：
   - `mapFile` 填新 TMX 文件名；
   - `facilities` 填该关卡拥有的家具；
   - 每关可以单独设置顾客资源和最大顾客数。
5. 创建关卡时传入配置，例如：

```dart
final level = RestaurantLevel1(config: level2Config);
```

当前第一关业务类仍叫 `RestaurantLevel1`。后续关卡规则相同时，可以将它重命名为
通用的 `RestaurantLevel`；规则不同时再组合新的业务系统。
