import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/features/setting/presentation/controller/SettingsController.dart';
import 'package:notepadclient/shared/theme/AppTheme.dart';

/// 右侧布局主体 — 常用控件预览面板
///
/// 作者: anoxia
/// 版本: 1.0.1
/// 创建时间: 2025-09-17
class LayoutBody extends StatefulWidget {
  const LayoutBody({super.key});

  @override
  State<LayoutBody> createState() => _LayoutBodyState();
}

SettingsController settingsController = getIt<SettingsController>();

class _LayoutBodyState extends State<LayoutBody> {
  // 交互状态：便于预览启用/禁用、选中/未选中等
  bool _switchValue = true;
  bool _checkboxValue = false;
  int _radioValue = 0;
  double _sliderValue = 30.0;
  String? _dropdownValue = 'One';
  final TextEditingController _textController = TextEditingController(text: '示例文本');
  double _linearProgress = 0.4;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('这是一个 SnackBar。')),
    );
  }

  void _showDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('示例对话框'),
        content: const Text('这是用于测试对话框主题的内容。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定')),
        ],
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('底部弹窗示例', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 局部用于快速读取 theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     

          const SizedBox(height: 12),

          // ---------- 按钮组，展示启用/禁用/边框/图标等 ----------
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton(onPressed: () {}, child: const Text("Filled / Enabled")),
            FilledButton(onPressed: null, child: const Text("Filled / Disabled")),
            ElevatedButton(onPressed: () {}, child: const Text("Elevated")),
            OutlinedButton(onPressed: () {}, child: const Text("Outlined")),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text("Outlined Icon")),
            TextButton(onPressed: () {}, child: const Text("TextButton")),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            // 小号图标按钮示例
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.add),
              tooltip: '禁用的 IconButton',
            ),
            // FAB 作为演示（小）
            FloatingActionButton.small(onPressed: () {}, child: const Icon(Icons.check)),
          ]),

          const SizedBox(height: 18),

          // ---------- 表单控件示例 ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('表单与输入', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: '文本输入',
                      hintText: '输入一些文本',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _dropdownValue,
                    items: const [
                      DropdownMenuItem(value: 'One', child: Text('One')),
                      DropdownMenuItem(value: 'Two', child: Text('Two')),
                      DropdownMenuItem(value: 'Three', child: Text('Three')),
                    ],
                    onChanged: (v) => setState(() => _dropdownValue = v),
                    decoration: const InputDecoration(labelText: '下拉选择'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ---------- 选择器（Switch/Checkbox/Radio/Slider） ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('选择控件', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Switch(
                      value: _switchValue,
                      onChanged: (v) => setState(() => _switchValue = v),
                    ),
                    const SizedBox(width: 8),
                    Text('Switch: ${_switchValue ? "On" : "Off"}'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(value: _checkboxValue, onChanged: (v) => setState(() => _checkboxValue = v ?? false)),
                    const SizedBox(width: 8),
                    Text('Checkbox: ${_checkboxValue ? "Checked" : "Unchecked"}'),
                  ],
                ),
                Row(children: [
                  Radio<int>(value: 0, groupValue: _radioValue, onChanged: (v) => setState(() => _radioValue = v ?? 0)),
                  const Text('Radio A'),
                  const SizedBox(width: 12),
                  Radio<int>(value: 1, groupValue: _radioValue, onChanged: (v) => setState(() => _radioValue = v ?? 0)),
                  const Text('Radio B'),
                ]),
                const SizedBox(height: 12),
                Text('Slider: ${_sliderValue.toStringAsFixed(0)}'),
                Slider(
                  min: 0,
                  max: 100,
                  value: _sliderValue,
                  onChanged: (v) => setState(() => _sliderValue = v),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 18),

          // ---------- 进度与指示器 ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('进度指示器', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _linearProgress),
                const SizedBox(height: 12),
                Row(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _linearProgress = (_linearProgress + 0.1).clamp(0.0, 1.0)),
                    child: const Text('增加进度'),
                  ),
                  const SizedBox(width: 8),
                  Text('${(_linearProgress * 100).round()}%'),
                ]),
              ]),
            ),
          ),

          const SizedBox(height: 18),

          // ---------- Chip / Tooltip / PopupMenu / Badge 简单演示 ----------
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: const Text('Chip'), onDeleted: () {}, deleteIcon: const Icon(Icons.close)),
            Tooltip(message: '提示文本', child: Icon(Icons.info_outline)),
            PopupMenuButton<int>(
              onSelected: (v) {},
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 1, child: Text('菜单一')),
                PopupMenuItem(value: 2, child: Text('菜单二')),
              ],
              child: OutlinedButton(onPressed: (){},child: const Text('PopupMenu')),
            ),
          ]),

          const SizedBox(height: 18),

          // ---------- 表格示例（DataTable） ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('DataTable 示例', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      DataRow(cells: [DataCell(Text('1')), DataCell(Text('Alice')), DataCell(Text('Active'))]),
                      DataRow(cells: [DataCell(Text('2')), DataCell(Text('Bob')), DataCell(Text('Disabled'))]),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 18),

          // ---------- 操作演示（SnackBar / Dialog / BottomSheet） ----------
          Row(children: [
            FilledButton(onPressed: _showSnackBar, child: const Text('Show SnackBar')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _showDialog, child: const Text('Show Dialog')),
            const SizedBox(width: 8),
            TextButton(onPressed: _showBottomSheet, child: const Text('Show BottomSheet')),
          ]),

          const SizedBox(height: 18),

          // ---------- 卡片与自定义内容 ----------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('卡片示例', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('使用 colorScheme.primary: ${colorScheme.primary}', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Row(children: [
                    FilledButton(onPressed: () {}, child: const Text('Primary Action')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
                  ]),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
