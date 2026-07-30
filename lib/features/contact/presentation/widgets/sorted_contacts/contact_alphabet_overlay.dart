import 'package:flutter/material.dart';

/// 字母索引滑动时的高亮浮层组件
class ContactAlphabetOverlay extends StatelessWidget {
  final dynamic symbol;

  const ContactAlphabetOverlay({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final safeSymbol = symbol.toString().trim().isEmpty
        ? '#'
        : symbol.toString();
    return Container(
      alignment: Alignment.center,
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        safeSymbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
