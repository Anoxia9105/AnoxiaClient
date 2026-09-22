# 我的日程 MVP

## 范围

首期提供个人日程的跨设备同步：

- 新建、编辑、删除日程
- 标题、备注、地点、开始/结束时间、全天标记
- 日、周、月、议程四种视图
- 今日与未来七天的快捷列表
- 议程按开始时间升序展示

首期不包含重复规则、提醒、共享、参与人、第三方日历同步、拖拽改期和离线写入队列。

## 客户端结构

| 层 | 文件/目录 | 职责 |
|---|---|---|
| UI | `lib/features/schedule/presentation/` | 日历视图、议程列表、编辑弹窗 |
| 状态 | `lib/framework/provider/schedule/schedule_service.dart` | 按当前视图窗口加载，封装增删改刷新 |
| 领域 | `lib/framework/domain/schedule_event.dart` | 事件模型、UTC 序列化、视图查询窗口 |
| 仓库接口 | `lib/domain/repositories/schedule_repository.dart` | 客户端数据契约 |
| HTTP 实现 | `lib/data/repositories/schedule_repository_impl.dart` | 调用 `/schedule/events` |

日历 UI 使用锁定版本 `calendar_view: 2.0.0`。2.x 可能包含破坏性更新，升级前必须重新验证 Web 和 Windows 的日/周/月视图。

## REST 契约

所有接口要求登录，服务端从认证上下文获取 `userId`，客户端不能指定资源所有者。

```text
GET    /schedule/events?from=<RFC3339>&to=<RFC3339>
GET    /schedule/events/{id}
POST   /schedule/events
PUT    /schedule/events/{id}
DELETE /schedule/events/{id}
```

列表查询为左闭右开窗口，并返回与窗口有交集的日程：

```sql
end_at > :from AND start_at < :to
```

查询窗口最长 370 天。创建和更新请求示例：

```json
{
  "title": "产品评审",
  "description": "确认 MVP 范围",
  "location": "线上",
  "startAt": "2026-09-22T01:00:00.000Z",
  "endAt": "2026-09-22T02:00:00.000Z",
  "timeZone": "UTC",
  "allDay": false,
  "color": "#4F6BED",
  "revision": 1
}
```

更新必须携带最近一次读取到的 `revision`。版本不一致时服务端拒绝覆盖，客户端提示刷新后重试。

## 数据库

- 全量初始化：`AnoxiaServer/anoxia.sql`
- 已有环境迁移：`AnoxiaServer/2026-09-22-schedule-event.sql`
- 普通日程以 UTC 瞬时时间保存；全天日程以 UTC 零点承载日期边界，跨时区展示不漂移
- `time_zone` 预留 IANA 时区标识，MVP 创建数据使用 `UTC`
- 查询和修改均包含 `user_id`，防止跨用户访问

部署服务端前必须先执行增量 SQL。

## 验证

```powershell
# 客户端
flutter pub get
dart run build_runner build
flutter test test/features/schedule/schedule_event_test.dart
flutter analyze

# 服务端
mvn test -pl system -am -Dtest=ScheduleEventServiceImplTest -Dsurefire.failIfNoSpecifiedTests=false
mvn clean compile -DskipTests -q
```

浏览器验证时重点检查 320、768、1024、1440 像素宽度，以及创建、编辑、删除、切换视图和跨月翻页。
