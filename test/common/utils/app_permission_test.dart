import 'package:anoxia/common/utils/AppPermission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('a normal denial is requested again on the next use', () async {
    final gateway = _FakePermissionGateway(
      statuses: [PermissionStatus.denied, PermissionStatus.denied],
      requests: [PermissionStatus.denied, PermissionStatus.granted],
    );
    final service = AppPermissionService(gateway: gateway);

    expect(
      await service.request(Permission.microphone),
      AppPermissionResult.denied,
    );
    expect(
      await service.request(Permission.microphone),
      AppPermissionResult.granted,
    );
    expect(gateway.requestCount, 2);
  });

  test(
    'permanent denial does not issue an ineffective system request',
    () async {
      final gateway = _FakePermissionGateway(
        statuses: [PermissionStatus.permanentlyDenied],
      );
      final service = AppPermissionService(gateway: gateway);

      expect(
        await service.request(Permission.camera),
        AppPermissionResult.settingsRequired,
      );
      expect(gateway.requestCount, 0);
    },
  );

  test('limited access is accepted only when the feature allows it', () async {
    final acceptedGateway = _FakePermissionGateway(
      statuses: [PermissionStatus.limited],
    );
    final accepted = AppPermissionService(gateway: acceptedGateway);
    expect(
      await accepted.request(Permission.photos, acceptLimited: true),
      AppPermissionResult.granted,
    );
    expect(acceptedGateway.requestCount, 0);
  });
}

class _FakePermissionGateway implements AppPermissionGateway {
  _FakePermissionGateway({
    required List<PermissionStatus> statuses,
    List<PermissionStatus> requests = const [],
  }) : _statuses = List.of(statuses),
       _requests = List.of(requests);

  final List<PermissionStatus> _statuses;
  final List<PermissionStatus> _requests;
  int requestCount = 0;

  @override
  Future<PermissionStatus> status(Permission permission) async {
    return _statuses.removeAt(0);
  }

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requestCount++;
    return _requests.removeAt(0);
  }

  @override
  Future<bool> openSettings() async => true;
}
