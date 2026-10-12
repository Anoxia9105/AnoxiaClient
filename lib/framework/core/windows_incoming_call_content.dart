import 'dart:convert';

/// 使用左侧圆形头像、右侧两行标题，下方由系统横向排列操作按钮。
/// 显式启用按钮样式，避免插件在设置 scenario 时省略 useButtonStyle。
String buildWindowsIncomingCallContent({
  required Map<String, dynamic> payload,
  required String title,
  required String body,
  required Uri avatar,
  required Uri rejectIcon,
  required Uri acceptIcon,
  required String rejectLabel,
  required String acceptLabel,
  required String rejectAction,
  required String acceptAction,
  Uri? voiceIcon,
  String? voiceLabel,
  String? voiceAction,
}) {
  String escape(String value) => const HtmlEscape().convert(value);
  String arguments([String? action]) => escape(
    jsonEncode({...payload, 'kind': 'incoming_call', 'actionId': ?action}),
  );
  String button(String label, String action, Uri icon, String style) =>
      '<action content="${escape(label)}" arguments="${arguments(action)}" '
      'activationType="foreground" imageUri="${escape(icon.toString())}" '
      'hint-buttonStyle="$style" hint-toolTip="${escape(label)}"/>';

  return '<toast scenario="incomingCall" duration="long" useButtonStyle="true" launch="${arguments()}">'
      '<visual><binding template="ToastGeneric">'
      '<image placement="appLogoOverride" src="${escape(avatar.toString())}" hint-crop="circle" alt="${escape(title)}"/>'
      '<text hint-maxLines="1">${escape(title)}</text>'
      '<text hint-maxLines="2">${escape(body)}</text>'
      '</binding></visual><actions>'
      '${button(rejectLabel, rejectAction, rejectIcon, 'Critical')}'
      '${button(acceptLabel, acceptAction, acceptIcon, 'Success')}'
      '${voiceIcon != null && voiceLabel != null && voiceAction != null ? button(voiceLabel, voiceAction, voiceIcon, 'Success') : ''}'
      '</actions></toast>';
}
