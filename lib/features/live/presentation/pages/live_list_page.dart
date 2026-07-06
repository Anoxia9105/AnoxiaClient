import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class LiveListPage extends StatefulWidget {
  const LiveListPage({super.key});

  @override
  State<LiveListPage> createState() => _LiveListPageState();
}

class _LiveListPageState extends State<LiveListPage> {
  final List<_RoomSummary> _rooms = [
    const _RoomSummary(roomId: 'demo-live', role: '主播', status: '可进入'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: DeviceUtil.isRealMobile(),
        title: Text('live_page_title'.tr()),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        children: [
          _LiveActionCard(
            icon: HugeIcons.strokeRoundedLiveStreaming01,
            title: 'live_start_title'.tr(),
            subtitle: 'live_start_subtitle'.tr(),
            actionLabel: 'live_start_action'.tr(),
            color: cs.primary,
            onTap: () => _openRoomDialog(context, isHost: true),
          ),
          const SizedBox(height: 14),
          _LiveActionCard(
            icon: HugeIcons.strokeRoundedVideo01,
            title: 'live_rooms_title'.tr(),
            subtitle: 'live_rooms_subtitle'.tr(),
            actionLabel: 'live_rooms_action'.tr(),
            color: cs.tertiary,
            onTap: () => _openRoomDialog(context, isHost: false),
          ),
          const SizedBox(height: 22),
          Text(
            '直播间列表',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_rooms.isEmpty)
            Text(
              '暂无直播间，先创建一个吧',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ..._rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveRoomPage(roomId: room.roomId, isHost: false),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.roomId,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${room.role} · ${room.status}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openRoomDialog(
    BuildContext context, {
    required bool isHost,
  }) async {
    final controller = TextEditingController(
      text: 'live-${DateTime.now().millisecondsSinceEpoch}',
    );

    final roomId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isHost ? '开始直播' : '进入直播间'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '房间号',
              hintText: '例如：live-001',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(isHost ? '开始' : '进入'),
            ),
          ],
        );
      },
    );

    final trimmed = (roomId ?? '').trim();
    if (!context.mounted || trimmed.isEmpty) {
      return;
    }

    if (!_rooms.any((item) => item.roomId == trimmed)) {
      setState(() {
        _rooms.add(
          _RoomSummary(
            roomId: trimmed,
            role: isHost ? '主播' : '观众',
            status: '准备就绪',
          ),
        );
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveRoomPage(roomId: trimmed, isHost: isHost),
      ),
    );
  }
}

class _LiveActionCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color color;
  final VoidCallback? onTap;

  const _LiveActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSummary {
  final String roomId;
  final String role;
  final String status;

  const _RoomSummary({
    required this.roomId,
    required this.role,
    required this.status,
  });
}
