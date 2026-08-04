import 'package:flutter/widgets.dart';

/// Web 端浏览器前进/后退按钮拦截器
///
/// 在 Web（JS / Wasm）端禁用浏览器返回/前进按钮，避免用户通过浏览器
/// 历史记录离开当前界面。机制说明：
/// - 使用 Router（go_router）时，浏览器返回/前进会触发引擎的
///   `pushRouteInformation` 平台消息（MultiEntriesBrowserHistory 不发送
///   popRoute），最终由 [didPushRouteInformation] 分发；
/// - 无 Router 场景兜底处理 [didPopRoute]（SingleEntryBrowserHistory）。
/// 返回 true 表示消息已被消费，阻断其继续传递给 go_router 的
/// GoRouteInformationProvider / RootBackButtonDispatcher，使前进/后退
/// 按钮失效。
///
/// 注意：必须作为【第一个】WidgetsBindingObserver 注册（先于任何 Router
/// / WidgetsApp 创建），否则 go_router 会先消费消息，本拦截器不会生效。
class WebNavigationBlocker extends WidgetsBindingObserver {
  @override
  Future<bool> didPopRoute() async => true;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async =>
      true;
}