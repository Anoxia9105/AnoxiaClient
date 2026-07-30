import 'package:flutter/material.dart';

/// 公共资料信息行
///
/// 以标签-值形式展示一项公开资料
class PublicInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const PublicInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
