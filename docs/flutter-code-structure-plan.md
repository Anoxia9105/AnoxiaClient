# Flutter 代码结构优化方案（NotePadClient）

> 更新时间：2026-05-14
> 当前已落地示例：`settings` 功能已按此方案迁移到 `lib/features/settings`

## 推荐目录结构（Feature First）

```text
lib/
  app/
    bootstrap/
    router/
    theme/
  core/
    constants/
    extensions/
    network/
    utils/
    widgets/
  features/
    chat/
      application/      # Riverpod 状态、用例编排
      data/             # repository、dto、api
      domain/           # entity、value object
      presentation/
        pages/
        widgets/
    contact/
    settings/
    update/
```

## 迁移规则

1. 页面文件仅保留：
   - 布局组合
   - 路由参数处理
   - 与 UI 强相关的临时 controller（如 `TextEditingController`）
2. 可复用业务状态全部进入 `application/`，由 Riverpod 承担。
3. 组件拆分建议：
   - 单文件超过 300 行 → 必拆
   - 单文件超过 500 行 → 优先拆
4. 兼容性策略：
   - 旧路径保留导出文件（`export`）
   - 路由与外部 import 逐步迁移，避免一次性大改

## 下一批建议迁移优先级（按复杂度与收益）

1. `lib/pages/update/UpdatePage.dart`（543 行）
2. `lib/pages/contact/AddFriendPage.dart`（748 行）
3. `lib/pages/chat/component/ChatRoomList.dart`（673 行）
4. `lib/pages/chat/component/widget/ChatAppBar.dart`（664 行）
5. `lib/pages/chat/component/widget/ChatInputField.dart`（615 行）

## 本次已完成（settings）

- 新建：`lib/features/settings/application/settings_page_controller.dart`
- 新建：`lib/features/settings/presentation/pages/settings_page.dart`
- 新建：`lib/features/settings/presentation/widgets/*`
- 兼容导出：
  - `lib/pages/setting/SettingsPage.dart`
  - `lib/pages/setting/SettingItemCard.dart`

这样可以在不破坏现有路由的前提下，逐步把页面逻辑迁移为可维护的模块化结构。
