import 'package:flutter/material.dart';

class SettingItemCard extends StatelessWidget {
  const SettingItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题 icon
            Row(
              children: [
                Icon(Icons.settings,color: theme.primaryColor,),
                const SizedBox(width: 8),
                Text("Setting Title"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
