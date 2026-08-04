import 'package:anoxia/features/chat/presentation/pages/member_basic_info_page.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final member = ChatRoomMemberVO(
    userId: 42,
    nickName: '测试成员',
    avatar: null,
    sex: '0',
    phoneNumber: '13800138000',
    onlineStatus: true,
  );

  testWidgets('renders the member basic info for a non-contact member', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MemberBasicInfoPage(member: member)),
    );

    expect(find.text('member_basic_info_title'.tr()), findsOneWidget);
    expect(find.text('测试成员'), findsOneWidget);
    expect(find.text('member_not_contact_hint'.tr()), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('contact_online'.tr()), findsOneWidget);
    expect(find.text('contact_male'.tr()), findsOneWidget);
    expect(find.text('13800138000'), findsOneWidget);
    expect(find.text('contact_phone'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows offline/unknown fallbacks when member data is missing', (
    tester,
  ) async {
    final sparseMember = ChatRoomMemberVO(
      userId: null,
      nickName: null,
      avatar: null,
      sex: null,
      phoneNumber: null,
      onlineStatus: null,
    );

    await tester.pumpWidget(
      MaterialApp(home: MemberBasicInfoPage(member: sparseMember)),
    );

    expect(find.text('contact_offline'.tr()), findsOneWidget);
    expect(find.text('contact_unknown_gender'.tr()), findsOneWidget);
    expect(find.text('contact_no_phone'.tr()), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}