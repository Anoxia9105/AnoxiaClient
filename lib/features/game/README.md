# 餐厅游戏基础结构

这套结构把地图、家具显示、家具摆放规则和关卡数据分开，方便逐项断点调试。

## 文件职责

- `models/restaurant_level_config.dart`：关卡与家具静态配置。新增关卡主要修改这里。
- `models/facility_placement.dart`：摆放成功/失败结果。
- `components/restaurant_map.dart`：等距坐标转换、墙体边界、碰撞和寻路。
- `components/restaurant_facility.dart`：家具图片、拖动、旋转和 Debug 绘制。
- `components/keyboard_waitress.dart`：WASD/方向键控制的女服务员测试角色。
- `components/facility_placement_controller.dart`：统一判断越界、家具重叠，并刷新寻路障碍。
- `restaurant_level/restaurant_level1.dart`：第一关顾客、点餐、厨房和服务员流程。

## 调试家具摆放

1. 点击“摆放家具”进入编辑模式。
2. 青色框是当前选中家具的占地；红色框表示本次移动或旋转失败。
3. 控制台搜索 `[家具摆放]`，可以看到家具坐标、方向、占地和失败原因。
4. 家具占地不等于 PNG 尺寸。请在 `FacilityConfig.verticalFootprint` 和
   `horizontalFootprint` 中调整家具真正接触地面的宽高。
5. `placementGap` 是家具之间保留的最小间距。桌椅图片仍穿插时优先调大占地，
   只需要增加留白时再调大间距。

Debug 颜色：橙色是普通家具占地，青色是选中家具，红色表示摆放失败；地图上的
红色区域是 Tiled 静态碰撞，紫色区域是家具生成的动态寻路障碍。

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

## 经济平衡与存档

- `models/restaurant_balance.dart` 集中保存初始金币、家具价格、工资、食材价格、
  配方、菜品售价和升级曲线。
- `models/restaurant_business_state.dart` 负责购买、雇佣、库存、营业状态、每日结算
  和 SharedPreferences 单存档。
- 新游戏默认 3500 金币；第一天基础开店投入约 2700，仍留有采购与周转空间。
- 每日营业 120 秒，结算包含营业收入、采购/升级/家具支出与员工工资。
