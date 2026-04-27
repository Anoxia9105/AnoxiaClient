import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomCallStatus {
  final bool calling;
  final int startTime;

  const RoomCallStatus({required this.calling, required this.startTime});

  const RoomCallStatus.idle() : calling = false, startTime = 0;

  factory RoomCallStatus.fromJson(Map<String, dynamic> json) {
    return RoomCallStatus(
      calling: json['calling'] == true,
      startTime: (json['startTime'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<RoomCallStatus> _fetchCallStatus(String roomId) async {
  if (roomId.isEmpty) return const RoomCallStatus.idle();

  final res = await DioClient().get(
    API.callStatus,
    queryParameters: {'roomId': roomId},
  );

  final data = res.data?['data'];
  if (data is Map<String, dynamic>) {
    return RoomCallStatus.fromJson(data);
  }
  return const RoomCallStatus.idle();
}

class CallStatusController extends Notifier<Map<String, RoomCallStatus>> {
  @override
  Map<String, RoomCallStatus> build() => {};

  final Set<String> _loadedRooms = <String>{};
  final Set<String> _loadingRooms = <String>{};

  RoomCallStatus statusOf(String roomId) {
    if (roomId.isEmpty) return const RoomCallStatus.idle();
    return state[roomId] ?? const RoomCallStatus.idle();
  }

  Future<void> ensureLoaded(String roomId) async {
    if (roomId.isEmpty) return;
    if (_loadedRooms.contains(roomId) || _loadingRooms.contains(roomId)) return;
    await refresh(roomId);
    _loadedRooms.add(roomId);
  }

  Future<void> refresh(String roomId) async {
    if (roomId.isEmpty) return;
    if (_loadingRooms.contains(roomId)) return;

    _loadingRooms.add(roomId);
    try {
      final next = await _fetchCallStatus(roomId);
      state = {...state, roomId: next};
    } catch (_) {
      // 忽略网络异常，保持旧状态
    } finally {
      _loadingRooms.remove(roomId);
    }
  }

  void markStarted(String roomId, {int? startTime}) {
    if (roomId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    state = {
      ...state,
      roomId: RoomCallStatus(
        calling: true,
        startTime: startTime != null && startTime > 0 ? startTime : now,
      ),
    };
    _loadedRooms.add(roomId);
  }

  void markEnded(String roomId) {
    if (roomId.isEmpty) return;
    state = {...state, roomId: const RoomCallStatus.idle()};
    _loadedRooms.add(roomId);
  }
}

final callStatusControllerProvider =
    NotifierProvider<CallStatusController, Map<String, RoomCallStatus>>(
      CallStatusController.new,
    );

final roomCallStatusProvider = Provider.family<RoomCallStatus, String>((ref, roomId) {
  return ref.watch(
    callStatusControllerProvider.select(
      (map) => map[roomId] ?? const RoomCallStatus.idle(),
    ),
  );
});
