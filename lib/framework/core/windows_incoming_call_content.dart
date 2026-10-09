import 'dart:convert';

/// 来电模式需要居中文字和内联头像，普通 appLogoOverride 在此模式下不可靠。
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
      '<text hint-callScenarioCenterAlign="true">${escape(title)}</text>'
      '<text hint-callScenarioCenterAlign="true">${escape(body)}</text>'
      '<image src="${escape(avatar.toString())}" alt="${escape(title)}"/>'
      '</binding></visual><actions>'
      '${button(rejectLabel, rejectAction, rejectIcon, 'Critical')}'
      '${button(acceptLabel, acceptAction, acceptIcon, 'Success')}'
      '${voiceIcon != null && voiceLabel != null && voiceAction != null ? button(voiceLabel, voiceAction, voiceIcon, 'Success') : ''}'
      '</actions></toast>';
}
