import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class LiveListPage extends StatefulWidget {
  const LiveListPage({super.key});

  @override
  State<LiveListPage> createState() => _LiveListPageState();
}

class _LiveListPageState extends State<LiveListPage> {
  final List<_RoomSummary> _rooms = [];
  bool _loadingRooms = false;

  @override
  void initState() {
    super.initState();
    _loadPublicRooms();
  }

  Future<void> _loadPublicRooms() async {
    setState(() => _loadingRooms = true);
    try {
      final res = await DioClient().get('/live/rooms');
      if (res.data?['code'] == 200 && mounted) {
        final data = res.data?['data'];
        final rooms = data is List
            ? data
                  .whereType<Map>()
                  .map((item) => _RoomSummary.fromJson(item))
                  .toList()
            : <_RoomSummary>[];
        setState(() {
          _rooms
            ..clear()
            ..addAll(rooms);
        });
      }
    } catch (e) {
      Toast.showNotificationNow('获取直播间列表失败：$e');
    } finally {
      if (mounted) {
        setState(() => _loadingRooms = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: DeviceUtil.isRealMobile(),
        title: Text('live_page_title'.tr()),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loadingRooms ? null : _loadPublicRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPublicRooms,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            _LiveActionCard(
              icon: HugeIcons.strokeRoundedLiveStreaming01,
              title: 'live_start_title'.tr(),
              subtitle: '选择公开直播会进入列表，私密直播只能通过房间号进入',
              actionLabel: 'live_start_action'.tr(),
              color: cs.primary,
              onTap: () => _openRoomDialog(context, isHost: true),
            ),
            const SizedBox(height: 14),
            _LiveActionCard(
              icon: HugeIcons.strokeRoundedVideo01,
              title: 'live_rooms_title'.tr(),
              subtitle: '观看公开直播，或输入房间号进入私密直播',
              actionLabel: 'live_rooms_action'.tr(),
              color: cs.tertiary,
              onTap: () => _openRoomDialog(context, isHost: false),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '公开直播间',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_loadingRooms)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_loadingRooms && _rooms.isEmpty)
              Text(
                '暂无公开直播间。私密直播不会显示在这里，需要通过房间号进入。',
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
                          builder: (_) => LiveRoomPage(
                            roomId: room.roomId,
                            isHost: false,
                            visibility: LiveVisibility.public,
                          ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${room.hostName} · ${room.statusText}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '公开',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
      ),
    );
  }

  Future<void> _openRoomDialog(
    BuildContext context, {
    required bool isHost,
  }) async {
    final controller = TextEditingController(
      text: isHost ? 'live-${DateTime.now().millisecondsSinceEpoch}' : '',
    );
    var visibility = LiveVisibility.public;

    final result = await showDialog<_LiveRoomDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isHost ? '开始直播' : '进入直播间'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '房间号',
                      hintText: '例如：live-001',
                    ),
                  ),
                  if (isHost) ...[
                    const SizedBox(height: 16),
                    SegmentedButton<LiveVisibility>(
                      segments: const [
                        ButtonSegment(
                          value: LiveVisibility.public,
                          icon: Icon(Icons.public),
                          label: Text('公开'),
                        ),
                        ButtonSegment(
                          value: LiveVisibility.private,
                          icon: Icon(Icons.lock_outline),
                          label: Text('私密'),
                        ),
                      ],
                      selected: {visibility},
                      onSelectionChanged: (value) {
                        setDialogState(() => visibility = value.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        visibility == LiveVisibility.public
                            ? '公开直播会显示在直播间列表，平台用户都可以观看。'
                            : '私密直播不会出现在列表，观众只能通过房间号进入。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _LiveRoomDialogResult(
                      roomId: controller.text.trim(),
                      visibility: visibility,
                    ),
                  ),
                  child: Text(isHost ? '开始' : '进入'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    final roomId = (result?.roomId ?? '').trim();
    if (!context.mounted || roomId.isEmpty) {
      return;
    }

    try {
      if (isHost) {
        await _startLive(roomId, result!.visibility);
        if (result.visibility == LiveVisibility.public) {
          await _loadPublicRooms();
        }
      } else {
        await _ensureRoomExists(roomId);
      }
    } catch (e) {
      Toast.showNotificationNow(isHost ? '开播失败：$e' : '进入直播间失败：$e');
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveRoomPage(
          roomId: roomId,
          isHost: isHost,
          visibility: result?.visibility ?? LiveVisibility.private,
        ),
      ),
    );

    if (mounted) {
      await _loadPublicRooms();
    }
  }

  Future<void> _startLive(String roomId, LiveVisibility visibility) async {
    final res = await DioClient().post(
      '/live/start',
      data: {'roomId': roomId, 'visibility': visibility.serverValue},
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '未知错误');
    }
  }

  Future<void> _ensureRoomExists(String roomId) async {
    final res = await DioClient().get(
      '/live/detail',
      queryParameters: {'roomId': roomId},
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '直播间不存在');
    }
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
  final String hostName;
  final String statusText;

  const _RoomSummary({
    required this.roomId,
    required this.hostName,
    required this.statusText,
  });

  factory _RoomSummary.fromJson(Map<dynamic, dynamic> json) {
    return _RoomSummary(
      roomId: json['roomId']?.toString() ?? '',
      hostName: json['hostName']?.toString().isNotEmpty == true
          ? json['hostName'].toString()
          : '主播',
      statusText: json['status']?.toString() == 'LIVE' ? '直播中' : '可进入',
    );
  }
}

class _LiveRoomDialogResult {
  final String roomId;
  final LiveVisibility visibility;

  const _LiveRoomDialogResult({required this.roomId, required this.visibility});
}

extension _LiveVisibilityServerValue on LiveVisibility {
  String get serverValue {
    switch (this) {
      case LiveVisibility.public:
        return 'PUBLIC';
      case LiveVisibility.private:
        return 'PRIVATE';
    }
  }
}
