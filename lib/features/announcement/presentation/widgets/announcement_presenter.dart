import 'dart:async';

import 'package:anoxia/features/announcement/presentation/widgets/announcement_dialog.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/provider/announcement/announcement_controller.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 根级公告弹窗协调器，Provider 仅维护状态，不持有 UI 上下文。
class AnnouncementPresenter extends ConsumerStatefulWidget {
  const AnnouncementPresenter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AnnouncementPresenter> createState() =>
      _AnnouncementPresenterState();
}

class _AnnouncementPresenterState extends ConsumerState<AnnouncementPresenter>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;
  String? _showingIdentity;
  int? _sessionUserId;
  Route<void>? _dialogRoute;
  bool _dialogInvalidated = false;
  DateTime? _lastForegroundRefresh;
  final Set<String> _shownNormalIdentities = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(announcementControllerProvider, (_, _) {
      _closeInvalidDialog();
      _schedule();
    });
    ref.listenManual(authControllerProvider, (_, _) {
      _closeInvalidDialog();
      _syncSessionUser();
      _schedule();
    });
    ref.listenManual(callInvitationControllerProvider, (_, _) => _schedule());
    ref.listenManual(
      mobileCallSessionControllerProvider,
      (_, _) => _schedule(),
    );
    ref.listenManual(callWindowControllerProvider, (_, _) => _schedule());
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        ref.read(authControllerProvider).value == null) {
      return;
    }
    final now = DateTime.now();
    if (_lastForegroundRefresh != null &&
        now.difference(_lastForegroundRefresh!) < const Duration(minutes: 1)) {
      return;
    }
    _lastForegroundRefresh = now;
    unawaited(ref.read(announcementControllerProvider.notifier).refresh());
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNext());
  }

  Future<void> _showNext() async {
    if (!mounted || _dialogOpen) return;
    if (ref.read(callInvitationControllerProvider) != null ||
        ref.read(mobileCallSessionControllerProvider) != null ||
        ref.read(callWindowControllerProvider) != null) {
      return;
    }
    final userId = ref.read(authControllerProvider).value?.userId;
    if (userId == null) return;
    _syncSessionUser();
    final pending = ref.read(announcementControllerProvider).pending;
    final candidates = pending
        .where(
          (item) =>
              item.level == AnnouncementLevel.required ||
              !_shownNormalIdentities.contains(item.identity),
        )
        .toList();
    if (candidates.isEmpty) return;
    final item = candidates.first;
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    _dialogOpen = true;
    _dialogInvalidated = false;
    _showingIdentity = item.identity;
    final required = item.level == AnnouncementLevel.required;
    if (!required) _shownNormalIdentities.add(item.identity);
    final route = AnnouncementDialog.buildRoute(
      context,
      (dialogContext) => AnnouncementDialog(
        announcement: item,
        onClose: () => Navigator.of(dialogContext).pop(),
        onAcknowledge: () async {
          if (ref.read(authControllerProvider).value?.userId != userId) {
            return false;
          }
          return ref
              .read(announcementControllerProvider.notifier)
              .acknowledge(item);
        },
        queueIndex: 0,
        queueTotal: candidates.length,
      ),
      dismissible: !required,
    );
    _dialogRoute = route;
    await Navigator.of(context, rootNavigator: true).push(route);
    if (!mounted) return;
    if (identical(_dialogRoute, route)) _dialogRoute = null;
    _dialogOpen = false;
    _showingIdentity = null;
    if (!required &&
        !_dialogInvalidated &&
        ref.read(authControllerProvider).value?.userId == userId) {
      await ref.read(announcementControllerProvider.notifier).markRead(item);
    }
    _schedule();
  }

  void _syncSessionUser() {
    final userId = ref.read(authControllerProvider).value?.userId;
    if (_sessionUserId == userId) return;
    _sessionUserId = userId;
    _shownNormalIdentities.clear();
  }

  void _closeInvalidDialog() {
    final route = _dialogRoute;
    final identity = _showingIdentity;
    if (route == null || identity == null) return;
    final currentUserId = ref.read(authControllerProvider).value?.userId;
    final stillActive = ref
        .read(announcementControllerProvider)
        .items
        .any((item) => item.identity == identity);
    if (currentUserId == _sessionUserId && stillActive) return;
    final navigator = route.navigator;
    if (navigator != null) {
      _dialogInvalidated = true;
      navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(announcementControllerProvider);
    return widget.child;
  }
}
