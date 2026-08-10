// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_image_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择/粘贴图片 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传

@ProviderFor(ChatImageUploadController)
final chatImageUploadControllerProvider = ChatImageUploadControllerProvider._();

/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择/粘贴图片 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
final class ChatImageUploadControllerProvider
    extends
        $NotifierProvider<ChatImageUploadController, Map<String, UploadEntry>> {
  /// 聊天图片上传控制器
  ///
  /// 处理图片选择、粘贴和上传功能。采用 keepAlive 模式确保跨页面共享状态。
  ///
  /// 核心流程：
  /// 1. 用户选择/粘贴图片 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
  /// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
  ///
  /// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
  ChatImageUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatImageUploadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatImageUploadControllerHash();

  @$internal
  @override
  ChatImageUploadController create() => ChatImageUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, UploadEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UploadEntry>>(value),
    );
  }
}

String _$chatImageUploadControllerHash() =>
    r'79cc056d9bf5f401d4ac6c18d37851c9faa87d72';

/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择/粘贴图片 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传

abstract class _$ChatImageUploadController
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
