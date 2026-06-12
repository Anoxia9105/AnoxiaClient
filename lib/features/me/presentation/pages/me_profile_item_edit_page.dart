import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MeProfileEditOption {
  const MeProfileEditOption({required this.value, required this.label});

  final String value;
  final String label;
}

class MeProfileItemEditPage extends StatefulWidget {
  const MeProfileItemEditPage.text({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    this.requiredMessage,
    this.keyboardType = TextInputType.text,
  }) : options = null;

  const MeProfileItemEditPage.select({
    super.key,
    required this.title,
    required this.initialValue,
    this.onSave,
    required this.options,
  }) : requiredMessage = null,
       keyboardType = TextInputType.text;

  final String title;
  final String initialValue;
  final Future<bool> Function(String value)? onSave;
  final String? requiredMessage;
  final TextInputType keyboardType;
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
      appBar: AppBar(
        centerTitle: true,
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
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = options[index];
        final selected = item.value == _selected;
        return ListTile(
          title: Text(item.label),
          trailing: selected
              ? Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => setState(() => _selected = item.value),
        );
      },
    );
  }
}
