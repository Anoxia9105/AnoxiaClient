import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class RoomTypeTag extends StatelessWidget {
  final bool isSingle;

  const RoomTypeTag({super.key, required this.isSingle});

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: isSingle
          ? HugeIcons.strokeRoundedUser02
          : HugeIcons.strokeRoundedUserGroup03,
      size: 16,
    );
  }
}
