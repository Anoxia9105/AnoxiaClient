import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MeProfileEditOption {
  const MeProfileEditOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// 桌面端资料编辑对话框。移动端继续使用下方的全屏编辑页面。
class MeProfileItemEditDialog extends StatefulWidget {
  const MeProfileItemEditDialog.text({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    this.requiredMessage,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  }) : options = null;

  const MeProfileItemEditDialog.select({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    required this.options,
  }) : requiredMessage = null,
       keyboardType = TextInputType.text,
       maxLength = null;

  final String title;
  final String initialValue;
  final Future<bool> Function(String value)? onSave;
  final String? requiredMessage;
  final TextInputType keyboardType;
  final int? maxLength;
  final List<MeProfileEditOption>? options;

  bool get isSelect => options != null;

  @override
  State<MeProfileItemEditDialog> createState() =>
      _MeProfileItemEditDialogState();
}

class _MeProfileItemEditDialogState extends State<MeProfileItemEditDialog> {
  late final TextEditingController _controller;
  late String _selected;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _selected = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = widget.isSelect ? _selected : _controller.text.trim();
    if (!widget.isSelect && widget.requiredMessage != null && value.isEmpty) {
      setState(() => _errorText = widget.requiredMessage);
      return;
    }
    if (value == widget.initialValue) {
      Navigator.of(context).pop(value);
      return;
    }
    if (widget.onSave != null) {
      setState(() => _saving = true);
      final ok = await widget.onSave!(value);
      if (!mounted) return;
      setState(() => _saving = false);
      if (!ok) return;
    }
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          HugeIcon(
            icon: widget.isSelect
                ? HugeIcons.strokeRoundedSlidersVertical
                : HugeIcons.strokeRoundedEdit02,
            color: cs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: widget.isSelect ? _buildOptions(cs) : _buildTextField(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('dialog_cancel'.tr()),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 18),
          label: Text('common_save'.tr()),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (!_saving) _save();
      },
      onChanged: (_) {
        if (_errorText != null) setState(() => _errorText = null);
      },
      decoration: InputDecoration(
        labelText: widget.title,
        border: const OutlineInputBorder(),
        errorText: _errorText,
      ),
    );
  }

  Widget _buildOptions(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.options!.map((option) {
        final selected = option.value == _selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(option.label),
              trailing: selected
                  ? HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: cs.primary)
                  : const HugeIcon(icon: HugeIcons.strokeRoundedCircle),
              onTap: _saving
                  ? null
                  : () => setState(() => _selected = option.value),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MeProfileItemEditPage extends StatefulWidget {
  const MeProfileItemEditPage.text({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    this.requiredMessage,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  }) : options = null;

  const MeProfileItemEditPage.select({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    required this.options,
  }) : requiredMessage = null,
       keyboardType = TextInputType.text,
       maxLength = null;

  final String title;
  final String initialValue;
  final Future<bool> Function(String value)? onSave;
  final String? requiredMessage;
  final TextInputType keyboardType;
  final int? maxLength;
  final List<MeProfileEditOption>? options;

  bool get isSelect => options != null;

  @override
  State<MeProfileItemEditPage> createState() => _MeProfileItemEditPageState();
}

class _MeProfileItemEditPageState extends State<MeProfileItemEditPage> {
  late final TextEditingController _controller;
  late String _selected;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _selected = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final value = widget.isSelect ? _selected : _controller.text.trim();

    if (!widget.isSelect && widget.requiredMessage != null && value.isEmpty) {
      setState(() => _errorText = widget.requiredMessage);
      return;
    }

    if (value == widget.initialValue) {
      Navigator.of(context).pop(value);
      return;
    }

    if (widget.onSave != null) {
      setState(() => _saving = true);
      final ok = await widget.onSave!(value);
      if (!mounted) return;
      setState(() => _saving = false);
      if (!ok) return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: DeviceUtil.isRealMobile(),
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onSave,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('common_save'.tr()),
          ),
        ],
      ),
      body: widget.isSelect ? _buildSelectBody() : _buildTextBody(),
    );
  }

  Widget _buildTextBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
      ),
    );
  }

  Widget _buildSelectBody() {
    final options = widget.options!;
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = options[index];
        final selected = item.value == _selected;
        return ListTile(
          title: Text(item.label),
          trailing: selected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedTick01,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => setState(() => _selected = item.value),
        );
      },
    );
  }
}
