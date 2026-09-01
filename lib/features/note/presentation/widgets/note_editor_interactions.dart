import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

class NoteTaskCheckboxBuilder implements QuillCheckboxBuilder {
  const NoteTaskCheckboxBuilder();

  @override
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        checked: isChecked,
        button: true,
        child: SizedBox(
          key: const ValueKey('note_task_checkbox_slot'),
          width: 26,
          height: 24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => onChanged(!isChecked),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 18,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: isChecked ? colors.primary : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isChecked
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: .45),
                          width: 1.4,
                        ),
                        borderRadius: BorderRadius.circular(RadiusToken.sm),
                      ),
                    ),
                    child: isChecked
                        ? Icon(Icons.check, size: 13, color: colors.onPrimary)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InlineSpan noteTextSpanBuilder(
  BuildContext context,
  Node node,
  int nodeOffset,
  String text,
  TextStyle? style,
  GestureRecognizer? recognizer,
) {
  final isLink = node.style.attributes.containsKey(Attribute.link.key);
  return TextSpan(
    text: text,
    style: style,
    recognizer: recognizer,
    mouseCursor: isLink || recognizer != null ? SystemMouseCursors.click : null,
  );
}
