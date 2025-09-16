# notepadclient
```
lib/
├─ main.dart
├─ app.dart                      # 应用入口 & 全局配置
├─ flavor.dart                   # 多环境配置
├─ core/                         # 核心通用模块（与业务无关）
│  ├─ constants/
│  │  ├─ env.dart                # 环境变量
│  │  └─ keys.dart               # 存储 Key、API Key
│  ├─ errors/
│  │  └─ api_exception.dart
│  ├─ network/                  #
│  │  ├─ dio_client.dart        # 封装 GET/POST 调用，拦截器（token、日志、错误处理）
│  │  ├─ dio_config.dart        # Dio 的基础配置
│  │  └─ token_storage.dart     # 专门管理 token 的持久化
│  ├─ storage/                  # 存储相关
│  │  └─ secure_storage_service.dart
│  ├─ di/                       #依赖注入
│  │  └─ injector.dart          # GetIt 注册
│  └─ utils/                    # 常用工具类
│     ├─ logger.dart
│     ├─ date_util.dart
│     ├─ debouncer.dart
│     └─ validators.dart
├─ features/                     # 业务功能模块
│  ├─ auth/                      
│  │  ├─ data/                   # 靠近网络 & 本地存储
│  │  │  ├─ models/              # DTO / JSON 序列化对象  
│  │  │  ├─ datasources/         # 网络请求 / 本地缓存
│  │  │  └─ repositories/        # 实现 domain 层定义的 Repository 接口
│  │  ├─ domain/
│  │  │  ├─entities              # 领域模型（不带第三方依赖）
│  │  │  ├─repositories          # 抽象接口，定义业务数据访问契约
│  │  │  └─ usecases/            # 单一业务动作（login、fetchMessages），组合 repositories
│  │  └─ presentation/           # UI 层
│  │     ├─ pages/               # 页面（Widget）
│  │     └─ providers/           # 状态管理（ChangeNotifier / Riverpod ）
│  └─ chat/
│     ├─ data/
│     ├─ domain/
│     └─ presentation/
├─ shared/                       # 跨 feature 复用 UI / widgets
│  ├─ widgets/                   # 自定义组件（Button、TextField、Dialog）。
│  ├─ theme/                     # 全局 ThemeData、颜色、字体、样式。
│  └─ i18n/                      # 国际化资源文件
└─ api/                          # API 定义（接口列表、路径常量）
    └─ endpoints.dart             # 定义所有接口路径常量，避免写死在 dataSource 中
```

核心要点：
 - presentation 调用 usecases，不直接碰 data。
 - usecases 调用 repositories，只依赖接口，不关心实现。
 - repositories 由 data 层实现，并通过 di 注入。


### 模块之间的依赖关系
```
main.dart
↓
app.dart
↓
features/xxx/presentation
↓
features/xxx/domain/usecases
↓
features/xxx/domain/repositories (接口)
↓
features/xxx/data/repositories (实现)
↓
features/xxx/data/datasources (API 调用)
↓
core/network, core/storage, api/endpoints
```

## 📁 Flutter 项目目录结构说明

| 路径 | 类型 | 说明 | 示例用途 |
|------|------|------|----------|
| `main.dart` | 入口文件 | 应用启动入口，调用 `runApp()` | 初始化 `App`，注入依赖 |
| `app.dart` | 应用配置 | 包含 `MaterialApp`、路由、主题等全局配置 | 设置路由表、主题、导航观察者 |
| `flavor.dart` | 环境配置 | 多环境支持（dev/staging/prod） | 切换 API 地址、日志级别等 |
| `core/` | 核心模块 | 与业务无关的通用工具和服务 | 网络、存储、日志、依赖注入等 |
| `core/constants/` | 常量 | 全局常量定义 | 环境变量、Key 名称等 |
| `core/errors/` | 错误处理 | 自定义异常类 | `ApiException`、`AuthException` |
| `core/network/` | 网络层 | Dio 配置、请求封装、Token 管理 | `DioClient`、拦截器、重试策略 |
| `core/storage/` | 本地存储 | 安全存储服务封装 | `flutter_secure_storage` 封装 |
| `core/di/` | 依赖注入 | `get_it` 注册与初始化 | 注册服务类、仓储类 |
| `core/utils/` | 工具类 | 通用工具函数 | 日期处理、日志封装、验证器 |
| `features/` | 业务模块 | 按功能拆分的业务代码 | 登录、聊天、设置等模块 |
| `features/auth/` | 登录模块 | 登录相关的数据、逻辑、UI | 用户模型、登录页面、状态管理 |
| `features/auth/data/` | 数据层 | 模型、数据源、仓储接口实现 | API 调用、缓存逻辑 |
| `features/auth/domain/` | 领域层 | UseCase、业务逻辑抽象 | 登录、注册、登出逻辑 |
| `features/auth/presentation/` | UI 层 | 页面、状态管理、组件 | 登录页、注册页、Provider |
| `features/chat/` | 聊天模块 | 聊天相关的业务代码 | 消息模型、聊天页面、会话逻辑 |
| `shared/` | 共享模块 | 跨模块复用的 UI 和配置 | 公共组件、主题、国际化 |
| `shared/widgets/` | 公共组件 | 可复用的 UI 组件 | 按钮、输入框、弹窗等 |
| `shared/theme/` | 主题配置 | 全局样式、颜色、字体 | `ThemeData`、颜色表 |
| `shared/i18n/` | 国际化 | 多语言支持 | `intl` 配置、翻译文件 |
| `api/` | API 定义 | 接口路径、参数常量 | `endpoints.dart` 定义所有 API 路径 |
| `repositories/` | 全局仓储 | 跨模块共享的仓储类 | 用户仓储、设置仓储等 |
| `generated/` | 自动生成 | `build_runner` 生成的代码 | `*.g.dart`、`*.freezed.dart` |
