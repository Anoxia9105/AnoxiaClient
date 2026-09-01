/// 设计令牌：圆角
///
/// 全项目统一使用这些圆角值，禁止在业务代码里随手写 `BorderRadius.circular(...)`。
/// 值来源与主题层保持一致：按钮/输入 6、卡片/弹窗 8、大容器 12/16、胶囊 999。
abstract final class RadiusToken {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;
}
