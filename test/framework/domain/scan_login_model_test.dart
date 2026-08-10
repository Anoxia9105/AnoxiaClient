import 'package:anoxia/framework/domain/scan_login_model.dart';
import 'package:anoxia/framework/provider/auth/scan_login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanLoginTicket', () {
    test('字段完整创建', () {
      const ticket = ScanLoginTicket(
        ticket: 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
        qrContent:
            'https://host/qrlogin?ticket=a1b2c3d4e5f60718293a4b5c6d7e8f90',
        expiresIn: 120,
      );

      expect(ticket.ticket, 'a1b2c3d4e5f60718293a4b5c6d7e8f90');
      expect(
        ticket.qrContent,
        'https://host/qrlogin?ticket=a1b2c3d4e5f60718293a4b5c6d7e8f90',
      );
      expect(ticket.expiresIn, 120);
    });
  });

  group('ScanLoginStatus 状态机', () {
    test('waiting 状态', () {
      const status = ScanLoginStatus(status: ScanLoginStatus.waiting);

      expect(status.isWaiting, isTrue);
      expect(status.isConfirmed, isFalse);
      expect(status.isExpired, isFalse);
      expect(status.token, isNull);
    });

    test('confirmed 状态携带 token', () {
      const status = ScanLoginStatus(
        status: ScanLoginStatus.confirmed,
        token: 'jwt-token-xxx',
      );

      expect(status.isConfirmed, isTrue);
      expect(status.isWaiting, isFalse);
      expect(status.isExpired, isFalse);
      expect(status.token, 'jwt-token-xxx');
    });

    test('confirmed 状态 token 为空时仍视为 confirmed', () {
      const status = ScanLoginStatus(status: ScanLoginStatus.confirmed);

      expect(status.isConfirmed, isTrue);
      expect(status.token, isNull);
    });

    test('expired 状态', () {
      const status = ScanLoginStatus(status: ScanLoginStatus.expired);

      expect(status.isExpired, isTrue);
      expect(status.isWaiting, isFalse);
      expect(status.isConfirmed, isFalse);
    });

    test('未知状态不匹配任何分支', () {
      const status = ScanLoginStatus(status: 'unknown');

      expect(status.isWaiting, isFalse);
      expect(status.isConfirmed, isFalse);
      expect(status.isExpired, isFalse);
    });
  });

  group('ScanLoginSession', () {
    const ticket = ScanLoginTicket(
      ticket: 'ticket-1',
      qrContent: 'https://host/qrlogin?ticket=ticket-1',
      expiresIn: 120,
    );

    test('未轮询时视为等待确认', () {
      const session = ScanLoginSession(ticket: ticket);

      expect(session.status, isNull);
      expect(session.isWaiting, isTrue);
    });

    test('waiting 状态仍为等待确认', () {
      const session = ScanLoginSession(
        ticket: ticket,
        status: ScanLoginStatus(status: ScanLoginStatus.waiting),
      );

      expect(session.isWaiting, isTrue);
    });

    test('confirmed / expired 状态不再等待确认', () {
      const confirmed = ScanLoginSession(
        ticket: ticket,
        status: ScanLoginStatus(
          status: ScanLoginStatus.confirmed,
          token: 'jwt-token-xxx',
        ),
      );
      const expired = ScanLoginSession(
        ticket: ticket,
        status: ScanLoginStatus(status: ScanLoginStatus.expired),
      );

      expect(confirmed.isWaiting, isFalse);
      expect(expired.isWaiting, isFalse);
    });
  });
}