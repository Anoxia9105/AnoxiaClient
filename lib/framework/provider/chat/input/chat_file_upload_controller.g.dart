// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_file_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天文件上传控制器
///
/// 处理文件选择和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择文件 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传

@ProviderFor(ChatFileUploadController)
final chatFileUploadControllerProvider = ChatFileUploadControllerProvider._();

/// 聊天文件上传控制器
///
/// 处理文件选择和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择文件 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
final class ChatFileUploadControllerProvider
    extends
        $NotifierProvider<ChatFileUploadController, Map<String, UploadEntry>> {
  /// 聊天文件上传控制器
  ///
  /// 处理文件选择和上传功能。采用 keepAlive 模式确保跨页面共享状态。
  ///
  /// 核心流程：
  /// 1. 用户选择文件 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
  /// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
  ///
  /// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
  ChatFileUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatFileUploadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatFileUploadControllerHash();

  @$internal
  @override
  ChatFileUploadController create() => ChatFileUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, UploadEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UploadEntry>>(value),
    );
  }
}

String _$chatFileUploadControllerHash() =>
    r'a567b388e11d98ab8f420ab74ce7e763a05a0ac5';

/// 聊天文件上传控制器
///
/// 处理文件选择和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择文件 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传

abstract class _$ChatFileUploadController
    extends $Notifier<Map<String, UploadEntry>> {
  Map<String, UploadEntry> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, UploadEntry>, Map<String, UploadEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, UploadEntry>, Map<String, UploadEntry>>,
              Map<String, UploadEntry>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
