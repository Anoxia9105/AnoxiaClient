import 'package:anoxia/features/chat/presentation/call/mobile/call_mobile_room_body.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/draggable_self_view.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/mobile_participant_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

// 不建立 WebRTC 连接：保留真实事件监听与无视频成员画面的渲染。
class _ParticipantFake<T extends TrackPublication> extends Fake
    implements Participant<T> {
  _ParticipantFake(this.identity);

  @override
  final String identity;
  @override
  String get sid => identity;
  @override
  String? get metadata => null;
  @override
  bool get isSpeaking => false;
  @override
  ConnectionQuality get connectionQuality => ConnectionQuality.excellent;
  @override
  bool isMicrophoneEnabled() => true;

  final _events = EventsEmitter<ParticipantEvent>();
  @override
  EventsListener<ParticipantEvent> createListener({
    bool synchronized = false,
  }) => EventsListener(_events, synchronized: synchronized);
}

class _LocalParticipantFake
    extends _ParticipantFake<LocalTrackPublication<LocalTrack>>
    implements LocalParticipant {
  _LocalParticipantFake() : super('local');
  @override
  List<LocalTrackPublication<LocalVideoTrack>> get videoTrackPublications => [];
}

class _RemoteParticipantFake
    extends _ParticipantFake<RemoteTrackPublication<RemoteTrack>>
    implements RemoteParticipant {
  _RemoteParticipantFake() : super('remote');
  @override
  List<RemoteTrackPublication<RemoteVideoTrack>> get videoTrackPublications =>
      [];
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 390, height: 640, child: child)),
);

void main() {
  testWidgets('双人通话点击小窗后自己成为主画面，再次点击可切回对方', (tester) async {
    final local = _LocalParticipantFake();
    final remote = _RemoteParticipantFake();
    String? focused;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => MobileVideoLayout(
            participants: [local, remote],
            focusedParticipantIdentity: focused,
            onFocusChanged: (identity) => setState(() => focused = identity),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<DraggableSelfView>(find.byType(DraggableSelfView))
          .participant,
      same(local),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(DraggableSelfView),
        matching: find.byType(MobileParticipantSurface),
      ),
    );
    await tester.pump();
    expect(focused, local.identity);
    expect(
      tester
          .widget<DraggableSelfView>(find.byType(DraggableSelfView))
          .participant,
      same(remote),
    );
    expect(
      tester
          .widget<MobileParticipantSurface>(
            find.byKey(const ValueKey('mobile-primary-local')),
          )
          .participant,
      same(local),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(DraggableSelfView),
        matching: find.byType(MobileParticipantSurface),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<DraggableSelfView>(find.byType(DraggableSelfView))
          .participant,
      same(local),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('群通话只有两人且没有视频轨时仍以网格展示所有成员', (tester) async {
    await tester.pumpWidget(
      _host(
        MobileVideoLayout(
          participants: [_LocalParticipantFake(), _RemoteParticipantFake()],
          isGroup: true,
          focusedParticipantIdentity: null,
          onFocusChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(DraggableSelfView), findsNothing);
    expect(find.byType(MobileParticipantSurface), findsNWidgets(2));
    expect(find.text('local'), findsOneWidget);
    expect(find.text('remote'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('小窗一帧内连续拖动事件累计全部位移并立即跟手', (tester) async {
    await tester.pumpWidget(
      _host(DraggableSelfView(participant: _LocalParticipantFake())),
    );
    final surface = find.byType(MobileParticipantSurface);
    final gesture = await tester.startGesture(tester.getCenter(surface));
    // 首次位移越过手势识别阈值，再从已接受的拖动位置开始测量。
    await gesture.moveBy(const Offset(-30, -30));
    await tester.pump();
    final before = tester.getTopLeft(surface);
    await gesture.moveBy(const Offset(-12, -9));
    await gesture.moveBy(const Offset(-12, -9));
    await gesture.moveBy(const Offset(-12, -9));
    await tester.pump();

    expect(tester.getTopLeft(surface), before + const Offset(-36, -27));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
