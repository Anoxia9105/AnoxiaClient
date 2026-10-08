import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/framework/domain/forward_message.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForwardRecordDetailPage extends ConsumerStatefulWidget {
  final String recordId;
  final String targetMessageId;
  final String targetRoomId;
  const ForwardRecordDetailPage({
    super.key,
    required this.recordId,
    required this.targetMessageId,
    required this.targetRoomId,
  });
  @override
  ConsumerState<ForwardRecordDetailPage> createState() =>
      _ForwardRecordDetailPageState();
}

class _ForwardRecordDetailPageState
    extends ConsumerState<ForwardRecordDetailPage> {
  final List<ForwardRecordItem> _items = [];
  bool _loading = true;
  bool _failed = false;
  int _total = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .forwardRecord(
            widget.recordId,
            widget.targetMessageId,
            widget.targetRoomId,
            offset: _items.length,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('chat_forward_record'.tr())),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_failed) {
            return Column(
              children: [
                Text('chat_forward_record_unavailable'.tr()),
                TextButton(
                  onPressed: _load,
                  child: Text('chat_forward_retry'.tr()),
                ),
              ],
            );
          }
          if (_items.length < _total) {
            return TextButton(
              onPressed: _load,
              child: Text('chat_forward_load_more'.tr()),
            );
          }
          return const SizedBox.shrink();
        }
        final item = _items[index];
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(
                    url: item.authorAvatar,
                    name: item.authorName,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.authorName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    DateUtil.formatWeChatTimeDivider(
                      item.message.timestamp ?? 0,
                      context.locale.languageCode,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 仅呈现内容，不带源会话气泡的回复、撤回、收藏及多选菜单。
              MessageRenderFactory.getStrategy(
                item.message.messageType,
              ).buildContent(context, item.message, colors.onSurface),
            ],
          ),
        );
      },
    ),
  );
}
