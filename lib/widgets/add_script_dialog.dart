import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/command_item.dart';
import '../services/config_service.dart';
import '../theme/app_theme.dart';

class AddScriptDialog extends StatefulWidget {
  final Function(CommandItem) onSave;

  const AddScriptDialog({super.key, required this.onSave});

  @override
  State<AddScriptDialog> createState() => _AddScriptDialogState();
}

class _AddScriptDialogState extends State<AddScriptDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scriptPathController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedIcon = 'code';
  String _selectedColor = 'blue';
  String _selectedCategory = 'custom';
  bool _requiresAdmin = false;
  bool _hasParameters = false;
  bool _isImporting = false;

  final _categories = const [
    ('power', 'Питание', Icons.power_settings_new),
    ('system', 'Система', Iconsax.monitor),
    ('cleanup', 'Очистка', Iconsax.trash),
    ('network', 'Сеть', Iconsax.wifi),
    ('custom', 'Мои скрипты', Iconsax.code),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scriptPathController.dispose();
    super.dispose();
  }

  Future<void> _importScript() async {
    // TODO: Использовать file_picker для выбора .py файла
    // Пока просто подсказка
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Поместите .py файл в папку скриптов и введите имя файла'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final scriptName = _scriptPathController.text.trim();
    final command = CommandItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      scriptPath: scriptName.endsWith('.py') ? scriptName : '$scriptName.py',
      icon: _selectedIcon,
      category: _selectedCategory,
      color: _selectedColor,
      requiresAdmin: _requiresAdmin,
      hasParameters: _hasParameters,
    );

    widget.onSave(command);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Название',
                        hint: 'Например: Очистка логов',
                        icon: Iconsax.text,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Описание',
                        hint: 'Краткое описание действия',
                        icon: Iconsax.document_text,
                      ),
                      const SizedBox(height: 16),

                      _buildScriptPathField(),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Категория'),
                      const SizedBox(height: 8),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Иконка'),
                      const SizedBox(height: 8),
                      _buildIconSelector(),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Цвет'),
                      const SizedBox(height: 8),
                      _buildColorSelector(),
                      const SizedBox(height: 20),

                      _buildToggles(),
                      const SizedBox(height: 24),

                      _buildButtons(),
                    ],
                  ),
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
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Iconsax.add_square,
                color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Добавить скрипт',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Создайте новую команду для запуска',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.close_circle, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 14),
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
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildScriptPathField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.document_code,
                size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Text(
              'Имя скрипта',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isImporting ? null : _importScript,
              icon: const Icon(Iconsax.import_1, size: 14),
              label: const Text('Импорт', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _scriptPathController,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Укажите имя скрипта' : null,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'my_script.py',
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppTheme.bgDark,
            suffixText: '.py',
            suffixStyle: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.7)),
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
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : AppTheme.bgDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : AppTheme.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.$3,
                    size: 16,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  cat.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconSelector() {
    final icons = CommandItem.iconMap;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: icons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = icons.entries.elementAt(index);
          final isSelected = _selectedIcon == entry.key;

          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? CommandItem.colorMap[_selectedColor]!
                        .withValues(alpha: 0.2)
                    : AppTheme.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? CommandItem.colorMap[_selectedColor]!
                          .withValues(alpha: 0.5)
                      : AppTheme.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                entry.value,
                size: 22,
                color: isSelected
                    ? CommandItem.colorMap[_selectedColor]
                    : AppTheme.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector() {
    final colors = CommandItem.colorMap;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.entries.map((entry) {
        final isSelected = _selectedColor == entry.key;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: entry.value.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggles() {
    return Column(
      children: [
        _buildToggleTile(
          icon: Iconsax.shield_tick,
          title: 'Требуется Admin',
          subtitle: 'Скрипт нужно запускать с правами администратора',
          value: _requiresAdmin,
          color: AppTheme.warningColor,
          onChanged: (v) => setState(() => _requiresAdmin = v),
        ),
        const SizedBox(height: 12),
        _buildToggleTile(
          icon: Iconsax.setting_4,
          title: 'Есть параметры',
          subtitle: 'Показывать диалог настройки перед запуском',
          value: _hasParameters,
          color: AppTheme.primaryColor,
          onChanged: (v) => setState(() => _hasParameters = v),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.1)
              : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.3)
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? color : AppTheme.textMuted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: value ? Colors.white : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: const Text(
              'Отмена',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Iconsax.add, size: 18),
            label: const Text('Добавить',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}