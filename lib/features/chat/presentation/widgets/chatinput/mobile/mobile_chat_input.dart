import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/voice_record_controller.dart';
import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/platform/shims/image_cropper_shim.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/smart_reply_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/mobile_chat_ai_panel.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';

import 'chat_more_panel.dart';
import 'mobile_chat_input_widgets.dart';

/// 移动端聊天输入组件
///
/// 提供移动端专用的聊天输入界面，支持：
/// - 文本输入（支持 @提及）
/// - 语音录制（支持滑动取消）
/// - 表情选择
/// - 图片/文件上传
/// - 文本/语音模式切换
class MobileChatInput extends ConsumerStatefulWidget {
  /// 房间 ID
  final String roomId;

  /// 底部面板关闭回调
  final VoidCallback bottomSheet;

  const MobileChatInput({
    super.key,
    required this.roomId,
    required this.bottomSheet,
  });

  @override
  ConsumerState<MobileChatInput> createState() => _MobileChatInputState();
}

class _MobileChatInputState extends ConsumerState<MobileChatInput> {
  bool _isVoiceMode = false;
  bool _isVoicePressing = false;
  ChatBottomPanelType _currentPanelType = ChatBottomPanelType.none;
  MobileBottomPanelType? _currentOtherPanelType;

  final ChatBottomPanelContainerController<MobileBottomPanelType>
  _panelController =
      ChatBottomPanelContainerController<MobileBottomPanelType>();

  late final FocusNode _focusNode;
  late final MobileTextInputController _inputController;
  late final VoiceRecordController _voiceController;

  @override
  void initState() {
    super.initState();
    _focusNode = ref.read(chatFocusNodeProvider(widget.roomId));
    // 监听键盘焦点变化，驱动胶囊输入框的聚焦高亮
    _focusNode.addListener(_handleFocusChanged);
    _inputController = MobileTextInputController();
    _voiceController = VoiceRecordController()
      ..onMaxDurationReached = _onVoiceMaxDuration;

    // 预热权限与临时目录，降低首次长按录音的启动延迟。
    // Web 端 path_provider 无实现（getTemporaryDirectory 抛 MissingPluginException），
    // 且网页不支持本地录音，因此跳过预热，避免 SP/PC 模式切换重建时崩溃。
    if (!DeviceUtil.isWeb) {
      unawaited(_voiceController.warmUp());
    }
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onVoiceMaxDuration() {
    _voiceController.hideOverlay();
    _voiceController.forceEnd().then((result) {
      if (result != null && mounted) {
        ref
            .read(chatInputControllerProvider(widget.roomId).notifier)
            .sendVoiceMessage(
              filePath: result.filePath,
              durationMs: result.durationMs,
            );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _inputController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    final triggered = _inputController.checkMentionTrigger(value);
    _inputController.handleTextChanged(value);
    ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .handlePlainTextChanged(value);
    if (triggered) _showMentionSheet();
  }

  void _showMentionSheet() {
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
    final room = ref.read(currentRoomProvider(widget.roomId));
    // 仅群聊支持 @所有人，单聊不展示
    final users = <MentionUser>[
      if (room?.roomType == 1) MentionUser.atAll(),
      ...roomMembers
          .where((m) => m.userId != null && m.userId != currentUser?.userId)
          .map(
            (m) => MentionUser(
              id: m.userId!,
              name: m.nickName ?? 'chat_unknown_user_label'.tr(),
              avatar: m.avatar,
            ),
          ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          width: double.infinity,
          child: MentionListWidget(
            users: users,
            onUserSelected: (user) {
              Navigator.of(ctx).pop();
              if (user.isAll) {
                _inputController.insertMentionAll();
              } else {
                _inputController.insertMention(user.id, user.name);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSend(FileType type, bool isImage) async {
    if (isImage && DeviceUtil.isRealMobile()) {
      await _pickCropAndSendImagesMobile();
      return;
    }

    final result = await FilePicker.pickFiles(allowMultiple: true, type: type);
    if (result == null || result.files.isEmpty || !mounted) return;

    // 先收起面板，再交给「即时发送」：气泡会立刻出现在列表里，
    // 上传进度直接反映在气泡上，不需要用户盯着空界面等上传。
    _closeAllPanels();
    await ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .sendPickedAttachments(result.files);
  }

  Future<void> _pickCropAndSendImagesMobile() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;

    final action = await _pickImageSelectionAction();
    if (action == null || !mounted) return;

    if (action == ImageSelectionAction.sendOriginal) {
      final originalFiles = <PlatformFile>[];
      for (final xFile in picked) {
        originalFiles.add(
          PlatformFile(
            name: path.basename(xFile.path),
            path: xFile.path,
            size: await xFile.length(),
          ),
        );
      }
      if (!mounted) return;
      _closeAllPanels();
      await ref
          .read(chatInputControllerProvider(widget.roomId).notifier)
          .sendPickedAttachments(originalFiles);
      return;
    }

    final ratio = await _pickAspectRatioPreset();
    if (!mounted) return;

    // 裁剪循环中有多次 await，提前捕获主题避免异步间隙后使用 context。
    final colorScheme = Theme.of(context).colorScheme;
    final croppedFiles = <PlatformFile>[];
    for (final xFile in picked) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: xFile.path,
        aspectRatio: ratio,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'toolbar_image'.tr(),
            toolbarWidgetColor: colorScheme.onPrimary,
            toolbarColor: colorScheme.primary,
            activeControlsWidgetColor: colorScheme.primary,
          ),
          IOSUiSettings(title: 'toolbar_image'.tr()),
        ],
      );

      if (cropped == null) {
        // 用户取消当前图片裁剪时，跳过该图片继续处理其它图片。
        continue;
      }

      final file = File(cropped.path);
      if (!await file.exists()) continue;
      final size = await file.length();
      croppedFiles.add(
        PlatformFile(
          name: path.basename(cropped.path),
          path: cropped.path,
          size: size,
        ),
      );
    }

    if (croppedFiles.isEmpty || !mounted) return;

    _closeAllPanels();
    await ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .sendPickedAttachments(croppedFiles);
  }

  Future<ImageSelectionAction?> _pickImageSelectionAction() {
    return showModalBottomSheet<ImageSelectionAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(ctx).pop(ImageSelectionAction.crop),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCrop,
                    size: 19,
                  ),
                  label: Text('chat_image_crop_action'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(ctx).pop(ImageSelectionAction.sendOriginal),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    size: 19,
                  ),
                  label: Text('toolbar_send'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<CropAspectRatio?> _pickAspectRatioPreset() async {
    final options = <({String label, CropAspectRatio? ratio})>[
      (label: 'chat_image_ratio_original'.tr(), ratio: null),
      (label: '1:1', ratio: const CropAspectRatio(ratioX: 1, ratioY: 1)),
      (label: '3:4', ratio: const CropAspectRatio(ratioX: 3, ratioY: 4)),
      (label: '4:3', ratio: const CropAspectRatio(ratioX: 4, ratioY: 3)),
      (label: '16:9', ratio: const CropAspectRatio(ratioX: 16, ratioY: 9)),
    ];

    final result = await showModalBottomSheet<CropAspectRatio?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'chat_image_ratio_title'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  title: Text(option.label),
                  onTap: () => Navigator.of(ctx).pop(option.ratio),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    // BottomSheet dismissed without selection defaults to original ratio.
    return result;
  }

  void _closeAllPanels() {
    _hidePanel();
    widget.bottomSheet();
  }

  void _hidePanel() {
    _focusNode.unfocus();
    if (_panelController.currentPanelType == ChatBottomPanelType.none) return;
    _panelController.updatePanelType(ChatBottomPanelType.none);
  }

  void _toggleOtherPanel(MobileBottomPanelType type) {
    final isSameOpen =
        _currentPanelType == ChatBottomPanelType.other &&
        _currentOtherPanelType == type;
    if (isSameOpen) {
      _hidePanel();
      return;
    }

    // 面板开启时强制切回文本输入模式，避免保留语音按住说话态。
    if (_isVoiceMode) {
      setState(() => _isVoiceMode = false);
    }

    // 先展开目标面板，再收起键盘，避免输入栏先掉底再顶起。
    _panelController.updatePanelType(ChatBottomPanelType.other, data: type);
    _focusNode.unfocus();
  }

  void _toggleVoiceMode() {
    setState(() => _isVoiceMode = !_isVoiceMode);
    if (_isVoiceMode) {
      _hidePanel();

      /// 申请权限
      _voiceController.requestPermission();
    } else {
      _focusNode.requestFocus();
    }
  }

  Widget _buildCompactButton({
    required String tooltipMessage,
    required VoidCallback onTap,
    required dynamic icon,
    Color? color,
  }) {
    return MobileCompactButton(
      tooltipMessage: tooltipMessage,
      onTap: onTap,
      icon: icon,
      color: color,
    );
  }

  /// 发送按钮（实心主题色圆角方块）
  ///
  /// 与更多按钮同为 40×40 触控区，切换时无尺寸差导致的位移；
  /// 圆角 12 与输入胶囊一致。
  Widget _buildSendButton({required VoidCallback onTap}) {
    return MobileSendButton(onTap: onTap);
  }

  /// 胶囊输入容器（文本 / 语音共用）
  ///
  /// 圆角胶囊视觉：常态浅色悬浮，聚焦 / 录音时主题色高亮描边，
  /// 阴影随状态增强，自动适配亮暗主题。
  Widget _buildInputCapsule({required Widget child}) {
    final isRecording = _voiceController.isRecording;
    final isActive = _focusNode.hasFocus || _isVoicePressing || isRecording;
    return MobileInputCapsule(
      isActive: isActive,
      isRecording: isRecording,
      hasFocus: _focusNode.hasFocus,
      child: child,
    );
  }

  /// 文本输入胶囊（键盘模式）
  Widget _buildTextCapsule() {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));
    return _buildInputCapsule(
      child: TextField(
        controller: _inputController.textController,
        focusNode: focusNode,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(fontSize: 15),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: 'chat_input_placeholder'.tr(),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        onChanged: _handleTextChanged,
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          _panelController.updatePanelType(ChatBottomPanelType.keyboard);
          widget.bottomSheet();
        },
      ),
    );
  }

  /// 语音输入胶囊（按住说话模式）
  Widget _buildVoiceCapsule() {
    return ListenableBuilder(
      listenable: _voiceController,
      builder: (_, _) {
        final isRecording = _voiceController.isRecording;
        return _buildInputCapsule(
          child: MobileVoiceCapsuleContent(
            isPressing: _isVoicePressing,
            isRecording: isRecording,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));
    final replyTarget = ref.watch(replyTargetProvider(widget.roomId));

    final isInPipMode = ref.watch(
      mobileCallSessionControllerProvider.select(
        (s) => s?.isInPipMode ?? false,
      ),
    );
    if (isInPipMode) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTarget != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: ReplyPreviewBar(
              message: replyTarget,
              onClear: () {
                ref
                    .read(replyTargetControllerProvider.notifier)
                    .clear(widget.roomId);
              },
            ),
          ),
        // 智能回复建议条（手动触发，点击 chip 填入输入框）
        SmartReplyBar(
          roomId: widget.roomId,
          onPick: _inputController.insertTextAtCursor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 语音/键盘切换按钮
              // Web 端 audio_waveforms 无实现（麦克风权限/录音均不可用），隐藏语音入口。
              if (!DeviceUtil.isWeb)
                _buildCompactButton(
                  tooltipMessage: _isVoiceMode
                      ? 'toolbar_keyboard'.tr()
                      : 'toolbar_mic'.tr(),
                  onTap: _toggleVoiceMode,
                  icon: _isVoiceMode
                      ? HugeIcons.strokeRoundedKeyboard
                      : HugeIcons.strokeRoundedMic01,
                ),
              Expanded(
                // Web 端隐藏语音按钮后，输入区左侧补充内边距，避免文本紧贴屏幕边缘。
                child: Padding(
                  padding: EdgeInsets.only(left: DeviceUtil.isWeb ? 8 : 0),
                  child: _isVoiceMode
                      ? GestureDetector(
                          onLongPressDown: (_) {
                            if (!mounted) return;
                            setState(() => _isVoicePressing = true);
                          },
                          onLongPressStart: (d) async {
                            if (context.mounted) {
                              _voiceController.showOverlay(context);
                            }

                            unawaited(
                              _voiceController.onStart(d).then((_) {
                                // 若启动失败（如权限被拒）则立即收起覆盖层。
                                if (!_voiceController.isRecording) {
                                  _voiceController.hideOverlay();
                                }
                              }),
                            );
                          },
                          onLongPressMoveUpdate: _voiceController.onUpdate,
                          onLongPressCancel: () {
                            if (!mounted) return;
                            setState(() => _isVoicePressing = false);
                            _voiceController.hideOverlay();
                            unawaited(
                              _voiceController.cancelCurrentRecording(),
                            );
                          },
                          onLongPressEnd: (d) async {
                            if (mounted) {
                              setState(() => _isVoicePressing = false);
                            }
                            _voiceController.hideOverlay();
                            final result = await _voiceController.onEnd(d);
                            if (result != null && mounted) {
                              ref
                                  .read(
                                    chatInputControllerProvider(
                                      widget.roomId,
                                    ).notifier,
                                  )
                                  .sendVoiceMessage(
                                    filePath: result.filePath,
                                    durationMs: result.durationMs,
                                  );
                            }
                          },
                          child: _buildVoiceCapsule(),
                        )
                      : _buildTextCapsule(),
                ),
              ),
              // AI 助手按钮：受服务端 noteEnabled 控制，关闭时隐藏
              Builder(
                builder: (_) {
                  final noteEnabled =
                      ref.watch(aiFeatureFlagsProvider).value?.noteEnabled ??
                      true;
                  if (!noteEnabled) return const SizedBox.shrink();
                  return _buildCompactButton(
                    tooltipMessage: 'chat_ai.assist_title'.tr(),
                    onTap: () => _toggleOtherPanel(MobileBottomPanelType.ai),
                    icon:
                        _currentPanelType == ChatBottomPanelType.other &&
                            _currentOtherPanelType == MobileBottomPanelType.ai
                        ? HugeIcons.strokeRoundedCancel01
                        : HugeIcons.strokeRoundedSparkles,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              // 表情按钮
              _buildCompactButton(
                tooltipMessage: 'toolbar_emoji'.tr(),
                onTap: () => _toggleOtherPanel(MobileBottomPanelType.emoji),
                icon:
                    _currentPanelType == ChatBottomPanelType.other &&
                        _currentOtherPanelType == MobileBottomPanelType.emoji
                    ? HugeIcons.strokeRoundedKeyboard
                    : HugeIcons.strokeRoundedRelieved02,
              ),
              // 发送/更多按钮
              ListenableBuilder(
                listenable: _inputController,
                builder: (_, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _inputController.isEmpty
                      ? Row(
                          key: const ValueKey('empty_state_buttons'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactButton(
                              tooltipMessage: 'toolbar_more'.tr(),
                              onTap: () =>
                                  _toggleOtherPanel(MobileBottomPanelType.more),
                              icon: HugeIcons.strokeRoundedAddSquare,
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('typing_state_button'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSendButton(
                              onTap: () {
                                final data = _inputController.buildSendData();
                                if (data == null) return;
                                final notifier = ref.read(
                                  chatInputControllerProvider(
                                    widget.roomId,
                                  ).notifier,
                                );
                                if (data.quillDelta != null) {
                                  notifier.sendMobileMentionMessage(
                                    data.text,
                                    data.quillDelta!,
                                    mentionIds: data.mentionIds,
                                    mentionAll: data.mentionAll,
                                  );
                                } else {
                                  notifier.sendPlainTextMessage(
                                    data.text,
                                    mentionIds: data.mentionIds,
                                    mentionAll: data.mentionAll,
                                  );
                                }
                                _inputController.clear();
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        if (_currentPanelType == ChatBottomPanelType.other)
          Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
        ChatBottomPanelContainer<MobileBottomPanelType>(
          controller: _panelController,
          inputFocusNode: focusNode,
          panelBgColor: colorScheme.surfaceContainerLow,
          onPanelTypeChange: (panelType, data) {
            if (!mounted) return;
            setState(() {
              _currentPanelType = panelType;
              _currentOtherPanelType = panelType == ChatBottomPanelType.other
                  ? data
                  : null;
            });
          },
          otherPanelWidget: (type) {
            if (type == null) return const SizedBox.shrink();
            // AI 助手面板需要独立的纵向空间承载结果预览：
            // 与其他面板共用 260 会把结果区压到几乎没有。
            final panelHeight = type == MobileBottomPanelType.ai
                ? (MediaQuery.sizeOf(context).height * 0.62).clamp(400.0, 600.0)
                : 260.0;
            return SizedBox(
              height: panelHeight + MediaQuery.of(context).padding.bottom,
              child: SafeArea(
                top: false,
                child: switch (type) {
                  MobileBottomPanelType.more => ChatMorePanel(
                    roomId: widget.roomId,
                    onPickFile: _pickAndSend,
                    onMentionTap: () {
                      _hidePanel();
                      _showMentionSheet();
                    },
                  ),
                  MobileBottomPanelType.ai => MobileChatAiPanel(
                    inputController: _inputController,
                    onClose: _hidePanel,
                  ),
                  MobileBottomPanelType.emoji => Padding(
                    padding: const EdgeInsets.all(8),
                    child: ChatEmojiWidget(
                      closeSelected: _closeAllPanels,
                      onEmojiSelected: _inputController.insertTextAtCursor,
                      onStickerSelected: (sticker) {
                        ref
                            .read(
                              chatInputControllerProvider(
                                widget.roomId,
                              ).notifier,
                            )
                            .sendStickerMessage(sticker);
                      },
                      showSearch: false,
                      // 手机端选中后保持面板打开，键盘不弹出也不整体收起
                      closeOnSelect: false,
                    ),
                  ),
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
