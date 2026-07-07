import 'dart:convert';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/live/presentation/pages/live_preview_page.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
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
                  .where((room) => room.roomId.isNotEmpty)
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
              subtitle: '先预览直播画面，开播后由服务端自动生成数字房间号',
              actionLabel: 'live_start_action'.tr(),
              color: cs.primary,
              onTap: _openStartDialog,
            ),
            const SizedBox(height: 14),
            _LiveActionCard(
              icon: HugeIcons.strokeRoundedVideo01,
              title: 'live_rooms_title'.tr(),
              subtitle: '观看公开直播，或输入房间号进入私密直播',
              actionLabel: 'live_rooms_action'.tr(),
              color: cs.tertiary,
              onTap: _openJoinDialog,
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
                      onTap: () => _openLiveWindow(
                        roomId: room.roomId,
                        title: room.title,
                        isHost: false,
                        visibility: LiveVisibility.public,
                        source: room.source,
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
                                    room.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${room.hostName} · 房间号 ${room.roomId} · ${room.statusText}',
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
                            const Icon(Icons.open_in_new),
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

  Future<void> _openStartDialog() async {
    var visibility = LiveVisibility.public;
    final selected = await showDialog<LiveVisibility>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('开播设置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 12),
                  Text(
                    visibility == LiveVisibility.public
                        ? '公开直播会显示在直播间列表，平台用户都可以观看。'
                        : '私密直播不会出现在列表，观众只能通过房间号进入。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(visibility),
                  child: const Text('预览画面'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LivePreviewPage(
          visibility: selected,
          onStart:
              ({required title, required visibility, required source}) async {
                final room = await _startLive(
                  title: title,
                  visibility: visibility,
                  source: source,
                );
                await _openLiveWindow(
                  roomId: room.roomId,
                  title: room.title,
                  isHost: true,
                  visibility: visibility,
                  source: source,
                );
                if (mounted) {
                  await _loadPublicRooms();
                }
              },
        ),
      ),
    );
  }

  Future<void> _openJoinDialog() async {
    final controller = TextEditingController();

    final roomId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('进入直播间'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '房间号',
              hintText: '请输入 8 位数字房间号',
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
              child: const Text('进入'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = (roomId ?? '').trim();
    if (!mounted || trimmed.isEmpty) return;

    try {
      final room = await _ensureRoomExists(trimmed);
      await _openLiveWindow(
        roomId: room.roomId,
        title: room.title,
        isHost: false,
        visibility: room.visibility,
        source: room.source,
      );
    } catch (e) {
      Toast.showNotificationNow('进入直播间失败：$e');
    }
  }

  Future<_RoomSummary> _startLive({
    required String title,
    required LiveVisibility visibility,
    required LiveSource source,
  }) async {
    final res = await DioClient().post(
      '/live/start',
      data: {
        'title': title,
        'visibility': visibility.serverValue,
        'source': source.serverValue,
      },
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '未知错误');
    }

    final data = res.data?['data'];
    if (data is Map) {
      return _RoomSummary.fromJson(data);
    }
    throw Exception('服务端未返回直播间信息');
  }

  Future<_RoomSummary> _ensureRoomExists(String roomId) async {
    final res = await DioClient().get(
      '/live/detail',
      queryParameters: {'roomId': roomId},
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '直播间不存在');
    }
    final data = res.data?['data'];
    if (data is Map) {
      return _RoomSummary.fromJson(data);
    }
    throw Exception('服务端未返回直播间信息');
  }

  Future<void> _openLiveWindow({
    required String roomId,
    required String title,
    required bool isHost,
    required LiveVisibility visibility,
    required LiveSource source,
  }) async {
    if (DeviceUtil.isRealDesktop()) {
      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: jsonEncode({
            'type': 'live',
            'title': title,
            'roomId': roomId,
            'isHost': isHost,
            'visibility': visibility.serverValue,
            'source': source.serverValue,
          }),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await controller.show();
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveRoomPage(
          roomId: roomId,
          title: title,
          isHost: isHost,
          visibility: visibility,
          source: source,
        ),
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
  final String title;
  final String hostName;
  final String statusText;
  final LiveVisibility visibility;
  final LiveSource source;

  const _RoomSummary({
    required this.roomId,
    required this.title,
    required this.hostName,
    required this.statusText,
    required this.visibility,
    required this.source,
  });

  factory _RoomSummary.fromJson(Map<dynamic, dynamic> json) {
    final roomId = json['roomId']?.toString() ?? '';
    final title = json['title']?.toString().trim();
    return _RoomSummary(
      roomId: roomId,
      title: title == null || title.isEmpty ? '未命名直播' : title,
      hostName: json['hostName']?.toString().isNotEmpty == true
          ? json['hostName'].toString()
          : '主播',
      statusText: json['status']?.toString() == 'LIVE' ? '直播中' : '可进入',
      visibility: json['visibility']?.toString() == 'PRIVATE'
          ? LiveVisibility.private
          : LiveVisibility.public,
      source: json['source']?.toString() == 'SCREEN'
          ? LiveSource.screen
          : LiveSource.camera,
    );
  }
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

extension _LiveSourceServerValue on LiveSource {
  String get serverValue {
    switch (this) {
      case LiveSource.camera:
        return 'CAMERA';
      case LiveSource.screen:
        return 'SCREEN';
    }
  }
}
