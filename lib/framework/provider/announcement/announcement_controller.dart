import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/provider/core/announcement_repository_provider.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef AnnouncementClientInfo = ({String platform, int versionCode});

class AnnouncementState {
  const AnnouncementState({
    this.items = const <Announcement>[],
    this.loading = false,
    this.error,
  });

  final List<Announcement> items;
  final bool loading;
  final Object? error;

  List<Announcement> get pending => pendingAnnouncements(items);

  AnnouncementState copyWith({
    List<Announcement>? items,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) => AnnouncementState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

List<Announcement> pendingAnnouncements(Iterable<Announcement> items) {
  final pending = items.where((item) {
    return item.level == AnnouncementLevel.required
        ? !item.acknowledged
        : !item.read;
  }).toList();
  pending.sort((a, b) {
    final level = b.level.index.compareTo(a.level.index);
    if (level != 0) return level;
    final published = b.publishAt.compareTo(a.publishAt);
    if (published != 0) return published;
    return a.id.compareTo(b.id);
  });
  return List<Announcement>.unmodifiable(pending);
}

final announcementControllerProvider =
    NotifierProvider<AnnouncementController, AnnouncementState>(
      AnnouncementController.new,
    );

class AnnouncementController extends Notifier<AnnouncementState> {
  AnnouncementController({
    Future<AnnouncementClientInfo> Function()? clientInfoLoader,
  }) : _clientInfoLoader = clientInfoLoader ?? _loadClientInfo;

  final Future<AnnouncementClientInfo> Function() _clientInfoLoader;
  Future<void>? _refreshing;

  @override
  AnnouncementState build() => const AnnouncementState();

  Future<void> refresh() {
    final current = _refreshing;
    if (current != null) return current;
    final task = _refresh();
    _refreshing = task;
    return task.whenComplete(() {
      if (identical(_refreshing, task)) _refreshing = null;
    });
  }

  Future<void> _refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final clientInfo = await _clientInfoLoader();
      final items = await ref
          .read(announcementRepositoryProvider)
          .fetchActive(
            platform: clientInfo.platform,
            versionCode: clientInfo.versionCode,
          );
      if (!ref.mounted) return;
      state = AnnouncementState(items: items);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<bool> markRead(Announcement item) => _updateStatus(item, false);

  Future<bool> acknowledge(Announcement item) => _updateStatus(item, true);

  Future<bool> _updateStatus(Announcement item, bool acknowledgement) async {
    try {
      final repository = ref.read(announcementRepositoryProvider);
      if (acknowledgement) {
        await repository.acknowledge(item.id, item.revision);
      } else {
        await repository.markRead(item.id, item.revision);
      }
      if (!ref.mounted) return false;
      state = state.copyWith(
        items: [
          for (final current in state.items)
            if (current.identity == item.identity)
              current.copyWith(
                read: acknowledgement ? current.read : true,
                acknowledged: acknowledgement ? true : current.acknowledged,
              )
            else
              current,
        ],
        clearError: true,
      );
      return true;
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: error);
      return false;
    }
  }
}

int parseBuildNumber(String value) => int.tryParse(value.trim()) ?? 0;

Future<AnnouncementClientInfo> _loadClientInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return (
    platform: resolveUpdateClientType(),
    versionCode: parseBuildNumber(packageInfo.buildNumber),
  );
}
