import 'package:flutter/material.dart';

/// 字母索引条单个符号组件
class ContactAlphabetSymbol extends StatelessWidget {
  final dynamic symbol;
  final bool isActive;

  const ContactAlphabetSymbol({
    super.key,
    required this.symbol,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final safeSymbol = symbol.toString().trim().isEmpty
        ? '#'
        : symbol.toString();
    return Center(
      child: Text(
        safeSymbol,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
