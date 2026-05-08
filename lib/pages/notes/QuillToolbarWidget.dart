import 'package:anoxia/common/widgets/Toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

// --- 新增的工具栏组件 ---
class MyQuillToolbar extends StatefulWidget {
  final QuillController controller;

  const MyQuillToolbar({super.key, required this.controller});

  @override
  State<MyQuillToolbar> createState() => _MyQuillToolbarState();
}

class _MyQuillToolbarState extends State<MyQuillToolbar> {
  late final QuillController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(_refresh);
  }

  void _refresh() {
    setState(() {}); // 每当 selection/style 改变，强制刷新
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // QuillIconTheme 方便复用
    final QuillIconTheme quillIconTheme = QuillIconTheme(
      iconButtonSelectedData: IconButtonData(
        color: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      iconButtonUnselectedData: IconButtonData(
        color: Colors.grey.shade600,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );

    return Wrap(
      direction: Axis.horizontal,
      children: [
        // 撤销/重做
        QuillToolbarHistoryButton(
          isUndo: true,
          options: QuillToolbarHistoryButtonOptions(
            iconSize: 12,
            tooltip: '撤销',
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
        QuillToolbarHistoryButton(
          isUndo: false,
          options: QuillToolbarHistoryButtonOptions(
            tooltip: '重做',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
        // 粗体/斜体/下划线/删除线/下标/上标/内联代码
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '加粗',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.bold,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '斜体',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.italic,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '下划线',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.underline,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '删除线',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.strikeThrough,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '下标',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.subscript,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '上标',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.superscript,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '内联代码',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.inlineCode,
        ),
        // 清除格式
        QuillToolbarClearFormatButton(
          options: QuillToolbarClearFormatButtonOptions(
            tooltip: '清除格式',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
        // 颜色选择
        Builder(
          builder: (context) => QuillToolbarColorButton(
            options: QuillToolbarColorButtonOptions(
              tooltip: '文字颜色',
              iconSize: 12,
              iconTheme: quillIconTheme,
              customOnPressedCallback: (ctl, isBg) async {
                Toast.showWidget(context, child: Text("Colors"));
              },
            ),
            controller: controller,
            isBackground: false,
          ),
        ),
        Builder(
          builder: (context) => QuillToolbarColorButton(
            options: QuillToolbarColorButtonOptions(
              tooltip: '背景颜色',
              iconSize: 12,
              iconTheme: quillIconTheme,
              customOnPressedCallback: (ctl, isBg) async {
              Toast.showWidget(
                  context,
                  child: Text("Background Colors"),
                );
              },
            ),
            controller: controller,
            isBackground: true,
          ),
        ),
        // 对齐方式
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '左对齐',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.leftAlignment,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '居中对齐',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.centerAlignment,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '右对齐',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.rightAlignment,
        ),
        buildHeaderButton(tooltip: 'H0', attr: Attribute.header),
        buildHeaderButton(tooltip: 'H1', attr: Attribute.h1),
        buildHeaderButton(tooltip: 'H2', attr: Attribute.h2),
        buildHeaderButton(tooltip: 'H3', attr: Attribute.h3),
        buildHeaderButton(tooltip: 'H4', attr: Attribute.h4),
        buildHeaderButton(tooltip: 'H5', attr: Attribute.h5),
        buildHeaderButton(tooltip: 'H6', attr: Attribute.h6),

        // 行高
        buildHeaderButton(
          tooltip: '1.0',
          attr: LineHeightAttribute.lineHeightNormal,
        ),
        buildHeaderButton(
          tooltip: '1.15',
          attr: LineHeightAttribute.lineHeightTight,
        ),
        buildHeaderButton(
          tooltip: '1.5',
          attr: LineHeightAttribute.lineHeightOneAndHalf,
        ),
        buildHeaderButton(
          tooltip: '2.0',
          attr: LineHeightAttribute.lineHeightDouble,
        ),
        // 列表
        QuillToolbarToggleCheckListButton(
          options: QuillToolbarToggleCheckListButtonOptions(
            tooltip: '任务列表',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '有序列表',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.ol,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '无序列表',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.ul,
        ),
        // 代码块和引用
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '代码块',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.codeBlock,
        ),
        QuillToolbarToggleStyleButton(
          options: QuillToolbarToggleStyleButtonOptions(
            tooltip: '引用',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          attribute: Attribute.blockQuote,
        ),
        // 缩进
        QuillToolbarIndentButton(
          options: QuillToolbarIndentButtonOptions(
            tooltip: '增加缩进',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          isIncrease: true,
        ),
        QuillToolbarIndentButton(
          options: QuillToolbarIndentButtonOptions(
            tooltip: '减少缩进',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
          isIncrease: false,
        ),
        // 链接和搜索
        QuillToolbarLinkStyleButton(
          options: QuillToolbarLinkStyleButtonOptions(
            tooltip: '插入链接',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
        QuillToolbarSearchButton(
          options: QuillToolbarSearchButtonOptions(
            tooltip: '搜索',
            iconSize: 12,
            iconTheme: quillIconTheme,
          ),
          controller: controller,
        ),
      ],
    );
  }

  Widget buildHeaderButton({required String tooltip, required Attribute attr}) {
    final attrs = controller.getSelectionStyle().attributes;
    final current = attrs[Attribute.header.key];
    final isSelected = current == attr;
    return IconButton(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      tooltip: tooltip,
      icon: Text(
        tooltip,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.indigo : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        final attrs = controller.getSelectionStyle().attributes;
        final current = attrs[Attribute.header.key];
        // 再次点击同样的 header 取消样式
        if (current == attr) {
          controller.formatSelection(Attribute.header);
        } else {
          controller.formatSelection(attr);
        }
      },
    );
  }
}
