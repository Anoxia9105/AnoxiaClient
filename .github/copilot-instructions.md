# Copilot Instructions for notepadclient

## 项目架构与目录结构
- 本项目为多端 Flutter 应用，采用分层架构（presentation/domain/data/core/shared）。
- 主要业务模块位于 `lib/features/`，每个模块（如 auth、chat、setting）均分为 data/domain/presentation 三层。
- 通用工具、依赖注入、网络、存储等位于 `lib/core/`，跨模块 UI/主题/国际化在 `lib/shared/`。
- API 路径常量集中在 `lib/api/endpoints.dart`，避免硬编码。

## 关键开发约定
- **依赖注入**：统一使用 `get_it`，注册在 `lib/core/di/injector.dart`。
- **网络请求**：通过 `core/network/dio_client.dart` 封装，支持拦截器、Token 管理、错误处理。
- **数据流**：presentation 层仅调用 usecases，不直接访问 data 层。usecases 只依赖 domain 层接口，具体实现由 data 层提供并通过 di 注入。
- **状态管理**：推荐 Provider/Riverpod，见 `features/xxx/presentation/providers/`。
- **国际化**：多语言资源在 `assets/i18n/`，支持中/英/日三语。
- **主题**：主题配置与切换在 `shared/theme/`，支持多套主题。

## 构建与运行
- 常用命令：
  - `flutter pub get` 获取依赖
  - `flutter run` 运行（支持多端）
  - `flutter test` 运行测试
  - `flutter build <platform>` 构建发布包
- Android/Windows/Mac/Linux/iOS 端均有对应原生工程，见各平台目录。
- 环境切换通过 `lib/flavor.dart`，入口分别为 `MainDev.dart`、`MainProd.dart`、`MainStg.dart`。

## 代码风格与模式
- 遵循 Dart/Flutter 官方风格，建议使用 `dart format`。
- 业务逻辑尽量写在 usecase/domain 层，UI 只做展示和交互。
- 避免在 Widget 里直接操作数据源或存储。
- 组件/样式/国际化优先复用 shared/ 下内容。

## 重要文件/目录速查
- `lib/core/di/injector.dart`：依赖注入注册
- `lib/core/network/dio_client.dart`：网络请求封装
- `lib/features/setting/presentation/pages/SettingPage.dart`：设置页示例，集成 Controller
- `lib/shared/theme/`：主题相关
- `lib/shared/i18n/`、`assets/i18n/`：国际化
- `lib/api/endpoints.dart`：API 路径

## 其他
- 自动生成代码（如 *.g.dart、*.freezed.dart）需用 `build_runner`。
- 详细目录说明见 `README.md`。

---
如需补充或有疑问，请在 PR 或 Issue 中说明。