import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 分区标签组件
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// 外观模式选择卡片
class ThemeModeTile extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final ThemeMode mode;
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;
  const ThemeModeTile({
    super.key,
    required this.label,
    required this.icon,
    required this.mode,
    required this.selectedMode,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = mode == selectedMode;
    return InkWell(
      borderRadius: BorderRadius.circular(RadiusToken.md),
      mouseCursor: SystemMouseCursors.click,
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(RadiusToken.md),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 20,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
            if (selected)
              HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// 强调色色块
class AccentSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AccentSwatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shadowColor = color.withValues(alpha: selected ? 0.34 : 0.18);
    return Tooltip(
      message: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(SpacingToken.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromColor(color).withLightness(0.68).withSaturation(0.65).toColor(),
                  color,
                  HSLColor.fromColor(color).withLightness(0.34).withSaturation(0.60).toColor(),
                ],
              ),
              border: Border.all(
                color: colorScheme.surface.withValues(alpha: 0.82),
                width: 1.4,
              ),
            ),
            child: selected
                ? Center(child: Icon(Icons.check, color: _contrastingTextColor(color), size: 20))
                : null,
          ),
        ),
      ),
    );
  }

  Color _contrastingTextColor(Color bg) => _readableOn(bg);
}

Color _readableOn(Color bg) {
  final lightness = HSLColor.fromColor(bg).lightness;
  return lightness > 0.6 ? Colors.black87 : Colors.white;
}

/// 自定义颜色行
class CustomColorRow extends StatelessWidget {
  final Color? customColor;
  final ValueChanged<Color> onPick;
  final VoidCallback onClear;
  const CustomColorRow({super.key, required this.customColor, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCustom = customColor != null;
    return Container(
      padding: const EdgeInsets.all(SpacingToken.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: isCustom ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isCustom ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: customColor ?? colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
              gradient: isCustom
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromColor(customColor!).withLightness(0.72).toColor(),
                        customColor!,
                        HSLColor.fromColor(customColor!).withLightness(0.38).toColor(),
                      ],
                    )
                  : null,
            ),
            child: isCustom
                ? Icon(Icons.palette, size: 20, color: _contrast(customColor!))
                : Icon(Icons.palette_outlined, size: 20, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: SpacingToken.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCustom ? 'settings_theme_custom_active'.tr() : 'settings_theme_custom_inactive'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isCustom
                      // ignore: deprecated_member_use
                      ? '#${customColor!.value.toRadixString(16).substring(2).toUpperCase()}'
                      : 'settings_theme_custom_hint'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingToken.sm),
          FilledButton.icon(
            onPressed: () => _showColorPicker(context),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedPaintBoard, size: 16, color: colorScheme.onPrimary),
            label: Text(isCustom ? 'settings_theme_custom_change'.tr() : 'settings_theme_custom_pick'.tr()),
          ),
          if (isCustom) ...[
            const SizedBox(width: SpacingToken.sm),
            IconButton(
              tooltip: 'settings_theme_custom_clear'.tr(),
              onPressed: onClear,
              icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Color _contrast(Color bg) => _readableOn(bg);

  Future<void> _showColorPicker(BuildContext context) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: customColor ?? const Color(0xFF5E66D0)),
    );
    if (result != null) onPick(result);
  }
}

/// 简易 HSV 取色器对话框（无额外依赖）
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const ColorPickerDialog({super.key, required this.initialColor});
  @override
  State<ColorPickerDialog> createState() => ColorPickerDialogState();
}

class ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _hsv;
  late TextEditingController _hexController;
  static const _presets = [
    Color(0xFF5E66D0), Color(0xFF4A8FE7), Color(0xFF2AA596), Color(0xFF2FA87A),
    Color(0xFFCE7A96), Color(0xFFE07A5F), Color(0xFF7A8EB5), Color(0xFF8CA89A),
    Color(0xFFA48EB5), Color(0xFFB8A99A), Color(0xFF7D6BCF), Color(0xFF3E5A73),
    Color(0xFF6B7787), Color(0xFFC9A13A), Color(0xFF4A9CC6), Color(0xFFC2A68A),
    Color(0xFFE57373), Color(0xFF81C784), Color(0xFFFFB74D), Color(0xFF64B5F6),
    Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFFFF8A65), Color(0xFFA1887F),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      // ignore: deprecated_member_use
      text: '#${widget.initialColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateHex(Color c) {
    // ignore: deprecated_member_use
    _hexController.text = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: Text('settings_theme_custom_dialog_title'.tr()),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Text(
                  // ignore: deprecated_member_use
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    color: _hsv.value > 0.6 ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: SpacingToken.lg),
              _buildSlider(
                label: 'H',
                value: _hsv.hue,
                max: 360,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withHue(v);
                  _updateHex(_hsv.toColor());
                }),
                activeColor: HSLColor.fromAHSL(1, _hsv.hue / 360 * 360, 1, 0.5).toColor(),
              ),
              _buildSlider(
                label: 'S',
                value: _hsv.saturation,
                max: 1,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withSaturation(v);
                  _updateHex(_hsv.toColor());
                }),
                activeColor: _hsv.withSaturation(1).toColor(),
              ),
              _buildSlider(
                label: 'V',
                value: _hsv.value,
                max: 1,
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withValue(v);
                  _updateHex(_hsv.toColor());
                }),
                activeColor: _hsv.withValue(1).toColor(),
              ),
              const SizedBox(height: SpacingToken.md),
              TextField(
                controller: _hexController,
                decoration: InputDecoration(
                  labelText: 'HEX',
                  prefixText: '#',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
                ),
                maxLength: 7,
                onSubmitted: (value) {
                  final hex = value.replaceAll('#', '').trim();
                  if (hex.length == 6) {
                    final intVal = int.tryParse(hex, radix: 16);
                    if (intVal != null) {
                      setState(() {
                        _hsv = HSVColor.fromColor(Color(0xFF000000 | intVal));
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: SpacingToken.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('settings_theme_custom_presets'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: SpacingToken.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _presets)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _hsv = HSVColor.fromColor(c);
                        _updateHex(c);
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: c == color ? Theme.of(context).colorScheme.primary : Colors.white,
                            width: c == color ? 2.5 : 1,
                          ),
                          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 6)],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('dialog_cancel'.tr())),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hsv.toColor()),
          child: Text('confirm'.tr()),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 48, child: Text(value.toStringAsFixed(value > 10 ? 0 : 2), textAlign: TextAlign.right)),
      ],
    );
  }
}
