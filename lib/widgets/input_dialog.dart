import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';

class InputDialogResult {
  final bool confirmed;
  final Map<String, dynamic> values;

  InputDialogResult({required this.confirmed, this.values = const {}});
}

enum InputFieldType { text, number, dropdown, toggle, folderPicker, filePicker }

class InputFieldConfig {
  final String key;
  final String label;
  final String? hint;
  final InputFieldType type;
  final dynamic defaultValue;
  final List<String>? options;
  final int? min;
  final int? max;
  final IconData? icon;
  final List<String>? allowedExtensions;

  const InputFieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.type = InputFieldType.text,
    this.defaultValue,
    this.options,
    this.min,
    this.max,
    this.icon,
    this.allowedExtensions,
  });
}

class InputDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<InputFieldConfig> fields;
  final String confirmText;
  final String cancelText;

  const InputDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Iconsax.setting_2,
    this.color = AppTheme.primaryColor,
    required this.fields,
    this.confirmText = 'Запустить',
    this.cancelText = 'Отмена',
  });

  static Future<InputDialogResult?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Iconsax.setting_2,
    Color color = AppTheme.primaryColor,
    required List<InputFieldConfig> fields,
    String confirmText = 'Запустить',
    String cancelText = 'Отмена',
  }) {
    return showDialog<InputDialogResult>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        fields: fields,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _values[field.key] = field.defaultValue;
      if (field.type == InputFieldType.text ||
          field.type == InputFieldType.number ||
          field.type == InputFieldType.folderPicker ||
          field.type == InputFieldType.filePicker) {
        _controllers[field.key] = TextEditingController(
          text: field.defaultValue?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    for (final field in widget.fields) {
      if (_controllers.containsKey(field.key)) {
        final text = _controllers[field.key]!.text;
        if (field.type == InputFieldType.number) {
          _values[field.key] = int.tryParse(text) ?? field.defaultValue ?? 0;
        } else {
          _values[field.key] = text;
        }
      }
    }
    Navigator.pop(context, InputDialogResult(confirmed: true, values: _values));
  }

  void _cancel() {
    Navigator.pop(context, InputDialogResult(confirmed: false));
  }

  Future<void> _pickFolder(String key) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку',
    );
    if (result != null) {
      setState(() {
        _controllers[key]?.text = result;
        _values[key] = result;
      });
    }
  }

  Future<void> _pickFile(String key, List<String>? allowedExtensions) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выберите файл',
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() {
        _controllers[key]?.text = result.files.first.path!;
        _values[key] = result.files.first.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.fields.map(_buildField),
                    const SizedBox(height: 24),
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            ),
            child: Icon(widget.icon, color: widget.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.subtitle!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _cancel,
            icon: const Icon(Iconsax.close_circle, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildField(InputFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (field.icon != null) ...[
                Icon(field.icon, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
              ],
              Text(field.label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(InputFieldConfig field) {
    switch (field.type) {
      case InputFieldType.number:
        return _buildNumberField(field);
      case InputFieldType.dropdown:
        return _buildDropdownField(field);
      case InputFieldType.toggle:
        return _buildToggleField(field);
      case InputFieldType.folderPicker:
        return _buildPathPicker(field, isFolder: true);
      case InputFieldType.filePicker:
        return _buildPathPicker(field, isFolder: false);
      case InputFieldType.text:
        return _buildTextField(field);
    }
  }

  Widget _buildPathPicker(InputFieldConfig field, {required bool isFolder}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controllers[field.key],
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(field.hint ?? (isFolder ? 'Выберите папку...' : 'Выберите файл...')),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              if (isFolder) {
                _pickFolder(field.key);
              } else {
                _pickFile(field.key, field.allowedExtensions);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withValues(alpha: 0.3)),
              ),
              child: Icon(
                isFolder ? Iconsax.folder_open : Iconsax.document,
                color: widget.color,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(InputFieldConfig field) {
    return TextFormField(
      controller: _controllers[field.key],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(field.hint ?? ''),
    );
  }

  Widget _buildNumberField(InputFieldConfig field) {
    return Row(
      children: [
        _buildNumberButton(
          icon: Icons.remove,
          onPressed: () {
            final current = int.tryParse(_controllers[field.key]!.text) ?? 0;
            final newValue = (current - 1).clamp(field.min ?? 0, field.max ?? 9999);
            _controllers[field.key]!.text = newValue.toString();
            setState(() {});
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _controllers[field.key],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: _inputDecoration(field.hint ?? '').copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildNumberButton(
          icon: Icons.add,
          onPressed: () {
            final current = int.tryParse(_controllers[field.key]!.text) ?? 0;
            final newValue = (current + 1).clamp(field.min ?? 0, field.max ?? 9999);
            _controllers[field.key]!.text = newValue.toString();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildNumberButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: AppTheme.bgDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Icon(icon, color: widget.color, size: 24),
        ),
      ),
    );
  }

  Widget _buildDropdownField(InputFieldConfig field) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _values[field.key]?.toString(),
          isExpanded: true,
          dropdownColor: AppTheme.bgCard,
          icon: const Icon(Iconsax.arrow_down_1, color: AppTheme.textSecondary),
          items: field.options?.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _values[field.key] = value),
        ),
      ),
    );
  }

  Widget _buildToggleField(InputFieldConfig field) {
    final value = _values[field.key] as bool? ?? false;
    return GestureDetector(
      onTap: () => setState(() => _values[field.key] = !value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? widget.color.withValues(alpha: 0.1) : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? widget.color.withValues(alpha: 0.3) : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(value ? Iconsax.tick_circle : Iconsax.close_circle,
                color: value ? widget.color : AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(value ? 'Включено' : 'Выключено',
                style: TextStyle(
                    color: value ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppTheme.bgDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.color),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _cancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Text(widget.cancelText,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.play, size: 18),
                const SizedBox(width: 8),
                Text(widget.confirmText,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}