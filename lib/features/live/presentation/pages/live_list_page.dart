import 'dart:convert';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/live/presentation/pages/live_preview_page.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:anoxia/framework/network/dio_client.dart';
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
      Toast.showNotificationNow('live_list_load_error'.tr(args: [e.toString()]));
    } finally {
      if (mounted) {
        setState(() => _loadingRooms = false);
      }
    }
  }

  Future<void> _openStartLiveDialog() async {
    final titleController = TextEditingController();
    var visibility = LiveVisibility.public;
    var source = LiveSource.camera;

    final draft = await showDialog<_StartLiveDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('live_create_new'.tr()),
              content: _StartLiveDialogBody(
                titleController: titleController,
                visibility: visibility,
                source: source,
                onVisibilityChanged: (value) {
                  setDialogState(() => visibility = value);
                },
                onSourceChanged: (value) {
                  setDialogState(() => source = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr()),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      Toast.showNotificationNow('live_title_required'.tr());
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      _StartLiveDraft(
                        title: title,
                        visibility: visibility,
                        source: source,
                      ),
                    );
                  },
                  icon: const Icon(Icons.live_tv),
                  label: Text('live_go_preview_start'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    if (draft == null || !mounted) return;

    await _openLivePreviewWindow(
      initialTitle: draft.title,
      visibility: draft.visibility,
      source: draft.source,
    );
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

  Future<void> _openLivePreviewWindow({
    required String initialTitle,
    required LiveVisibility visibility,
    required LiveSource source,
  }) async {
    if (DeviceUtil.isRealDesktop()) {
      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: jsonEncode({
            'type': 'live-preview',
            'title': initialTitle,
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
        builder: (previewContext) => LivePreviewPage(
          visibility: visibility,
          initialSource: source,
          initialTitle: initialTitle,
          onStart:
              ({required title, required visibility, required source, sourceId}) async {
                final room = await _startLive(
                  title: title,
                  visibility: visibility,
                  source: source,
                );
                if (!previewContext.mounted) return;
                await Navigator.of(previewContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LiveRoomPage(
                      roomId: room.roomId,
                      title: room.title,
                      isHost: true,
                      visibility: room.visibility,
                      source: room.source,
                      screenSourceId: sourceId,
                    ),
                  ),
                );
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
          title: Text('live_join_room_title'.tr()),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'live_room_id'.tr(),
              hintText: 'live_room_id_hint'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text('live_enter'.tr()),
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
      Toast.showNotificationNow('live_enter_failed'.tr(args: [e.toString()]));
    }
  }

  Future<_RoomSummary> _ensureRoomExists(String roomId) async {
    final res = await DioClient().get(
      '/live/detail',
      queryParameters: {'roomId': roomId},
    );
    if (res.data?['code'] != 200) {
      throw Exception(res.data?['msg'] ?? res.data?['message'] ?? 'live_room_not_found'.tr());
    }

    final data = res.data?['data'];
    if (data is Map) {
      return _RoomSummary.fromJson(data);
    }
    throw Exception('live_room_no_server_data'.tr());
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _LiveListAppBar(
        loadingRooms: _loadingRooms,
        onJoinTap: _openJoinDialog,
        onRefreshTap: _loadPublicRooms,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStartLiveDialog,
        icon: const Icon(Icons.add_to_photos_outlined),
        label: Text('live_start_action'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPublicRooms,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            _LiveActionCard(
              icon: HugeIcons.strokeRoundedVideo01,
              title: 'live_rooms_title'.tr(),
              subtitle: 'live_rooms_custom_subtitle'.tr(),
              actionLabel: 'live_join_by_room_id'.tr(),
              color: cs.tertiary,
              onTap: _openJoinDialog,
            ),
            const SizedBox(height: 18),
            _LiveRoomSectionHeader(loadingRooms: _loadingRooms),
            const SizedBox(height: 8),
            if (!_loadingRooms && _rooms.isEmpty)
              _LiveRoomEmptyHint(color: cs.onSurfaceVariant)
            else
              ..._rooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LiveRoomListItem(
                    room: room,
                    onTap: () => _openLiveWindow(
                      roomId: room.roomId,
                      title: room.title,
                      isHost: false,
                      visibility: room.visibility,
                      source: room.source,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool loadingRooms;
  final VoidCallback onJoinTap;
  final VoidCallback onRefreshTap;

  const _LiveListAppBar({
    required this.loadingRooms,
    required this.onJoinTap,
    required this.onRefreshTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: DeviceUtil.isRealMobile(),
      title: Text('live_page_title'.tr()),
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'live_join_by_room_id'.tr(),
          onPressed: onJoinTap,
          icon: const Icon(Icons.meeting_room_outlined),
        ),
        IconButton(
          tooltip: 'live_refresh_tooltip'.tr(),
          onPressed: loadingRooms ? null : onRefreshTap,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _LiveRoomSectionHeader extends StatelessWidget {
  final bool loadingRooms;

  const _LiveRoomSectionHeader({required this.loadingRooms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '公开直播间',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (loadingRooms)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
      ],
    );
  }
}

class _LiveRoomEmptyHint extends StatelessWidget {
  final Color color;

  const _LiveRoomEmptyHint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂无公开直播间。私密直播不会显示在这里，需要通过房间号进入。',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}

class _LiveRoomListItem extends StatelessWidget {
  final _RoomSummary room;
  final VoidCallback onTap;

  const _LiveRoomListItem({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.hostName} · 房间号 ${room.roomId} · ${room.statusText}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  room.visibility == LiveVisibility.private ? '私密' : '公开',
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
    );
  }
}

class _StartLiveDialogBody extends StatelessWidget {
  final TextEditingController titleController;
  final LiveVisibility visibility;
  final LiveSource source;
  final ValueChanged<LiveVisibility> onVisibilityChanged;
  final ValueChanged<LiveSource> onSourceChanged;

  const _StartLiveDialogBody({
    required this.titleController,
    required this.visibility,
    required this.source,
    required this.onVisibilityChanged,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'live_title_label'.tr(),
              hintText: 'live_title_hint_dialog'.tr(),
            ),
          ),
          const SizedBox(height: 8),
          _LiveSegmentBlock<LiveVisibility>(
            title: 'live_visibility'.tr(),
            segments: [
              ButtonSegment(
                value: LiveVisibility.public,
                icon: const Icon(Icons.public),
                label: Text('live_visibility_public'.tr()),
              ),
              ButtonSegment(
                value: LiveVisibility.private,
                icon: const Icon(Icons.lock_outline),
                label: Text('live_visibility_private'.tr()),
              ),
            ],
            selected: visibility,
            onChanged: onVisibilityChanged,
          ),
          const SizedBox(height: 10),
          _LiveSegmentBlock<LiveSource>(
            title: 'live_source'.tr(),
            segments: [
              ButtonSegment(
                value: LiveSource.camera,
                icon: const Icon(Icons.videocam),
                label: Text('live_source_camera'.tr()),
              ),
              ButtonSegment(
                value: LiveSource.screen,
                icon: const Icon(Icons.screen_share),
                label: Text('live_source_screen'.tr()),
              ),
            ],
            selected: source,
            onChanged: onSourceChanged,
          ),
        ],
      ),
    );
  }
}

class _LiveSegmentBlock<T> extends StatelessWidget {
  final String title;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const _LiveSegmentBlock({
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 6),
        SegmentedButton<T>(
          segments: segments,
          selected: {selected},
          onSelectionChanged: (value) {
            if (value.isNotEmpty) {
              onChanged(value.first);
            }
          },
        ),
      ],
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
              FilledButton.tonal(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
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

class _StartLiveDraft {
  final String title;
  final LiveVisibility visibility;
  final LiveSource source;

  const _StartLiveDraft({
    required this.title,
    required this.visibility,
    required this.source,
  });
}
