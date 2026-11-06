import 'dart:async';
import 'dart:ui' as ui;

import 'package:anoxia/common/widgets/app/mobile_bottom_bar.dart';
import 'package:anoxia/features/me/presentation/pages/me_page.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/design_test_app.dart';

class _Auth extends AuthController {
  _Auth(this.phase);
  final String phase;
  @override
  Future<UserInfo?> build() async {
    if (phase == 'loading') return Completer<UserInfo?>().future;
    if (phase == 'error') throw StateError('offline');
    return UserInfo(
      userId: 1,
      userName: 'anoxia',
      nickName: 'Anoxia',
      email: '',
      phoneNumber: '',
      sex: '2',
      avatar: '',
    );
  }
}

void main() {
  setUpAll(loadDesignFonts);
  for (final brightness in Brightness.values) {
    for (final phase in ['loading', 'profile', 'error']) {
      testWidgets('我的页和底栏共用背景，接缝无色差 $brightness $phase', (tester) async {
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(phase)),
            totalUnreadCountProvider.overrideWith((ref) => 0),
            pendingRequestCountProvider.overrideWith((ref) => 0),
          ],
        );
        addTearDown(container.dispose);
        final captureKey = GlobalKey();
        await tester.pumpWidget(
          designTestApp(
            container: container,
            locale: const Locale('zh'),
            brightness: brightness,
            captureKey: captureKey,
            child: Builder(
              builder: (context) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: Theme.of(
                    context,
                  ).extension<AppColors>()!.scaffoldGradient,
                ),
                child: const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: MyPage(),
                  bottomNavigationBar: MobileBottomBar(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        final boundaryY = tester
            .getRect(find.byKey(const Key('mobile-bottom-bar')))
            .top
            .round();
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          try {
            final pixels = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final before = ((boundaryY - 2) * image.width + 2) * 4;
            final after = ((boundaryY + 2) * image.width + 2) * 4;
            for (var channel = 0; channel < 3; channel++) {
              expect(
                (pixels!.getUint8(before + channel) -
                        pixels.getUint8(after + channel))
                    .abs(),
                lessThanOrEqualTo(2),
              );
            }
          } finally {
            image.dispose();
          }
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
