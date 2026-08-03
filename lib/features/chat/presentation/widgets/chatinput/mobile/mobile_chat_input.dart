import 'dart:async';
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
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/platform/shims/image_cropper_shim.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';

import 'chat_more_panel.dart';

enum _MobileBottomPanelType { emoji, more }

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
  _MobileBottomPanelType? _currentOtherPanelType;

  final ChatBottomPanelContainerController<_MobileBottomPanelType>
  _panelController =
      ChatBottomPanelContainerController<_MobileBottomPanelType>();

  late final FocusNode _focusNode;
  late final MobileTextInputController _inputController;
  late final VoiceRecordController _voiceController;

  @override
  void initState() {
    super.initState();
    _focusNode = ref.read(chatFocusNodeProvider(widget.roomId));
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

  void _onVoiceMaxDuration() {
    _voiceController.hideOverlay();
    _voiceController.forceEnd().then((result) {
      if (result != null && mounted) {
        ref
            .read(chatInputControllerProvider(widget.roomId).notifier)
            .sendVoiceMessage(
              filePath: result.filePath,
              duration: result.duration,
            );
      }
    });
  }

  @override
  void dispose() {
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
    final users = roomMembers
        .where((m) => m.userId != null && m.userId != currentUser?.userId)
        .map(
          (m) => MentionUser(
            id: m.userId!,
            name: m.nickName ?? 'chat_unknown_user_label'.tr(),
            avatar: m.avatar,
          ),
        )
        .toList();

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
              _inputController.insertMention(user.id, user.name);
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

    final notifier = ref.read(
      chatInputControllerProvider(widget.roomId).notifier,
    );
    if (isImage) {
      await notifier.sendPickedImages(result.files);
    } else {
      await notifier.sendPickedFiles(result.files);
    }
    _closeAllPanels();
  }

  Future<void> _pickCropAndSendImagesMobile() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;

    final ratio = await _pickAspectRatioPreset();
    if (!mounted) return;

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
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            toolbarColor: Theme.of(context).colorScheme.primary,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
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

    await ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .sendPickedImages(croppedFiles);
    _closeAllPanels();
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

  void _toggleOtherPanel(_MobileBottomPanelType type) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(8);
    return Tooltip(
      message: tooltipMessage,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HugeIcon(
              icon: icon,
              size: 24,
              color: color ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
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
                          unawaited(_voiceController.cancelCurrentRecording());
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
                                  duration: result.duration,
                                );
                          }
                        },
                        child: ListenableBuilder(
                          listenable: _voiceController,
                          builder: (_, _) => Container(
                            height: 40,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedScale(
                              scale: _isVoicePressing ? 0.98 : 1.0,
                              duration: const Duration(milliseconds: 80),
                              curve: Curves.easeOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                curve: Curves.easeOut,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _voiceController.isRecording
                                      ? colorScheme.primary
                                      : _isVoicePressing
                                      ? colorScheme.surfaceContainerHigh
                                      : colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('hold_to_talk'.tr()),
                              ),
                            ),
                          ),
                        ),
                      )
                    : TextField(
                        controller: _inputController.textController,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'chat_input_placeholder'.tr(),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _handleTextChanged,
                        onTap: () {
                          if (!_focusNode.hasFocus) {
                            _focusNode.requestFocus();
                          }
                          _panelController.updatePanelType(
                            ChatBottomPanelType.keyboard,
                          );
                          widget.bottomSheet();
                        },
                      ),
              ),
              // 表情按钮
              _buildCompactButton(
                tooltipMessage: 'toolbar_emoji'.tr(),
                onTap: () => _toggleOtherPanel(_MobileBottomPanelType.emoji),
                icon:
                    _currentPanelType == ChatBottomPanelType.other &&
                        _currentOtherPanelType == _MobileBottomPanelType.emoji
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
                              onTap: () => _toggleOtherPanel(
                                _MobileBottomPanelType.more,
                              ),
                              icon: HugeIcons.strokeRoundedAddSquare,
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('typing_state_button'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactButton(
                              tooltipMessage: 'toolbar_send'.tr(),
                              onTap: () {
                                final data = _inputController.buildSendData();
                                if (data == null) return;
                                ref
                                    .read(
                                      chatInputControllerProvider(
                                        widget.roomId,
                                      ).notifier,
                                    )
                                    .sendPlainTextMessage(
                                      data.text,
                                      mentionIds: data.mentionIds,
                                    );
                                _inputController.clear();
                              },
                              icon: HugeIcons.strokeRoundedSent,
                              color: colorScheme.primary,
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
        ChatBottomPanelContainer<_MobileBottomPanelType>(
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
            return SizedBox(
              height: 260.0 + MediaQuery.of(context).padding.bottom,
              child: SafeArea(
                top: false,
                child: switch (type) {
                  _MobileBottomPanelType.more => ChatMorePanel(
                    roomId: widget.roomId,
                    onPickFile: _pickAndSend,
                    onMentionTap: () {
                      _hidePanel();
                      _showMentionSheet();
                    },
                  ),
                  _MobileBottomPanelType.emoji => Padding(
                    padding: const EdgeInsets.all(8),
                    child: ChatEmojiWidget(
                      closeSelected: _closeAllPanels,
                      onEmojiSelected: _inputController.insertTextAtCursor,
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
