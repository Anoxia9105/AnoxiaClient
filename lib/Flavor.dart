/// 应用运行环境
/// - dev: 开发环境
/// - stg: 测试/预发布环境
/// - prod: 生产环境
enum Flavor { dev, stg, prod }

/// 环境配置参数
///
/// 用于存储当前运行环境下的配置，如 baseUrl、app 名称、调试开关等。
/// 通过 [FlavorConfig.instance] 获取。
class FlavorValues {
  /// 应用显示名称（不同环境可以显示不同）
  final String appName;

  /// API 请求的基础地址
  final String baseUrl;

  /// ws 请求基础地址
  final String wsBaseUrl;

  /// 是否开启调试模式（日志、调试工具等）
  final bool debug;


  /// 构建时间（方便排查问题时确认包版本）
  final String buildDate;

  /// 版本号（可通过 --dart-define 注入）
  final String appVersion;

  FlavorValues({
    this.appName = 'MyApp',
    required this.baseUrl,
    required this.wsBaseUrl,
    this.debug = false,
    String? buildDate,
    this.appVersion = '1.0.0',
  }) : buildDate = buildDate ?? DateTime.now().toIso8601String();
}

/// 全局环境配置（单例模式）
///
class FlavorConfig {
  final Flavor flavor;
  final FlavorValues values;

  static FlavorConfig? _instance;

  /// 私有构造函数
  FlavorConfig._internal(this.flavor, this.values);

  /// 初始化环境配置（只能初始化一次）
  static void init({required Flavor flavor, required FlavorValues values}) {
    if (_instance != null) {
      print('FlavorConfig 已经初始化过，不能重复初始化');
    }
    _instance = FlavorConfig._internal(flavor, values);
  }

  /// 获取单例实例
  static FlavorConfig get instance {
    if (_instance == null) {
      print('FlavorConfig 未初始化，请先调用 FlavorConfig.init()');
    }
    return _instance!;
  }

  /// 获取当前环境配置
  static FlavorValues get value => instance.values;

  /// 获取当前环境类型
  static Flavor get flavors => instance.flavor;

  /// 是否生产环境
  static bool get isProd => instance.flavor == Flavor.prod;

  /// 是否开发环境
  static bool get isDev => instance.flavor == Flavor.dev;

  /// 是否测试/预发布环境
  static bool get isStaging => instance.flavor == Flavor.stg;

  @override
  String toString() {
    return 'FlavorConfig{flavor: $flavor, appName: ${values.appName}, baseUrl: ${values.baseUrl}, debug: ${values.debug}}';
  }
}
