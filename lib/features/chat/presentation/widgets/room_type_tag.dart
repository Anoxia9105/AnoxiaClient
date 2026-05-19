import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RoomTypeTag extends StatelessWidget {
  final bool isSingle;

  const RoomTypeTag({super.key, required this.isSingle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isSingle
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.7)
        : colorScheme.primaryContainer.withValues(alpha: 0.8);
    final fgColor = isSingle
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSingle ? Icons.person_outline : Icons.groups_2_outlined,
            size: 11,
            color: fgColor,
          ),
          const SizedBox(width: 2),
          Text(
            isSingle ? 'chat_type_private'.tr() : 'chat_type_group'.tr(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
