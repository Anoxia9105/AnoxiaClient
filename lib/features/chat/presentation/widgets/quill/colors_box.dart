import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ColorsBox {
  static Widget buildColorsWidget(
    Function(String?)? onTap,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    // 💡 模拟 Google 文档色谱：8列，每列颜色由深到浅
    final List<List<Color>> colorColumns = [
      [
        Colors.black,
        Colors.grey[800]!,
        Colors.grey[700]!,
        Colors.grey[600]!,
        Colors.grey[500]!,
        Colors.grey[400]!,
        Colors.grey[300]!,
        Colors.white,
      ],
      [
        Colors.red[900]!,
        Colors.red[700]!,
        Colors.red[500]!,
        Colors.red[300]!,
        Colors.red[200]!,
        Colors.red[100]!,
        Colors.red[50]!,
        Colors.redAccent[100]!,
      ],
      [
        Colors.orange[900]!,
        Colors.orange[700]!,
        Colors.orange[500]!,
        Colors.orange[300]!,
        Colors.orange[200]!,
        Colors.orange[100]!,
        Colors.orange[50]!,
        Colors.orangeAccent[100]!,
      ],
      [
        Colors.yellow[900]!,
        Colors.yellow[700]!,
        Colors.yellow[500]!,
        Colors.yellow[300]!,
        Colors.yellow[200]!,
        Colors.yellow[100]!,
        Colors.yellow[50]!,
        Colors.yellowAccent[100]!,
      ],
      [
        Colors.green[900]!,
        Colors.green[700]!,
        Colors.green[500]!,
        Colors.green[300]!,
        Colors.green[200]!,
        Colors.green[100]!,
        Colors.green[50]!,
        Colors.greenAccent[100]!,
      ],
      [
        Colors.cyan[900]!,
        Colors.cyan[700]!,
        Colors.cyan[500]!,
        Colors.cyan[300]!,
        Colors.cyan[200]!,
        Colors.cyan[100]!,
        Colors.cyan[50]!,
        Colors.cyanAccent[100]!,
      ],
      [
        Colors.blue[900]!,
        Colors.blue[700]!,
        Colors.blue[500]!,
        Colors.blue[300]!,
        Colors.blue[200]!,
        Colors.blue[100]!,
        Colors.blue[50]!,
        Colors.blueAccent[100]!,
      ],
      [
        Colors.purple[900]!,
        Colors.purple[700]!,
        Colors.purple[500]!,
        Colors.purple[300]!,
        Colors.purple[200]!,
        Colors.purple[100]!,
        Colors.purple[50]!,
        Colors.purpleAccent[100]!,
      ],
    ];

    return Material(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      color: theme.colorScheme.surfaceBright,
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 重置按钮区
            InkWell(
              onTap: () => onTap?.call(null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_color_reset_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'toolbar_reset_color'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // 颜色矩阵区
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colorColumns
                    .map(
                      (column) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: column
                            .map(
                              (color) => _ColorItem(color: color, onTap: onTap),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}

class _ColorItem extends StatelessWidget {
  final Color color;
  final Function(String?)? onTap;

  const _ColorItem({required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // ✅ 修复：鼠标滑动变小手
      child: GestureDetector(
        onTap: () => onTap?.call('#${ColorsBox.colorToHex(color)}'),
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4), // 稍微圆角更好看
            border: Border.all(
              color: color == Colors.white
                  ? Colors.grey[300]!
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
