import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

/// 根据参与者连接质量构建信号强度图标
///
/// 根据不同的连接质量显示不同颜色和信号条数量：
/// - 优秀/良好：绿色，3格信号
/// - 较差：橙色，2格信号
/// - 丢失：红色，1格信号
/// - 未知：灰色，0格信号
Widget buildParticipantSignalIcon(Participant p) {
  final quality = p.connectionQuality;

  Color color;
  int level;
  String qualityLabel;

  switch (quality) {
    case ConnectionQuality.lost:
      color = Colors.redAccent;
      level = 1;
      qualityLabel = 'call_quality_lost'.tr();
      break;
    case ConnectionQuality.poor:
      color = Colors.orange;
      level = 2;
      qualityLabel = 'call_quality_poor'.tr();
      break;
    case ConnectionQuality.good:
    case ConnectionQuality.excellent:
      color = Colors.green;
      level = 3;
      qualityLabel = quality == ConnectionQuality.excellent
          ? 'call_quality_excellent'.tr()
          : 'call_quality_good'.tr();
      break;
    default:
      color = Colors.grey;
      level = 0;
      qualityLabel = 'call_quality_unknown'.tr();
  }

  Widget bar(int idx) {
    final active = level >= idx;
    final double h = 4.0 + idx * 3.0;
    return Container(
      width: 2.5,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        color: active ? color : Colors.white10,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  return Tooltip(
    message: qualityLabel,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bar(1), bar(2), bar(3)],
      ),
    ),
  );
}