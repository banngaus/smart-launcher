import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/command_item.dart';
import '../theme/app_theme.dart';
import '../widgets/input_dialog.dart';
import '../widgets/power_menu_dialog.dart';

class DialogResult {
  final bool proceed;
  final Map<String, String>? arguments;

  const DialogResult({required this.proceed, this.arguments});
  static const cancelled = DialogResult(proceed: false);
}

class DialogHandler {
  static final Map<String, Future<DialogResult> Function(BuildContext)> _handlers = {
    'power_manager.py': _handlePowerMenu,
    'kill_process.py': _handleKillProcess,
    'empty_recycle_bin.py': _handleRecycleBin,
    'find_duplicates.py': _handleFindDuplicates,
    'sort_files.py': _handleSortFiles,
    'clean_empty_folders.py': _handleCleanEmptyFolders,
    'batch_resize.py': _handleBatchResize,
    'extract_audio.py': _handleExtractAudio,
    'create_gif.py': _handleCreateGif,
  };

  static Future<DialogResult> handlePreRunDialog(
      BuildContext context, CommandItem command) async {
    final handler = _handlers[command.scriptPath];
    if (handler != null) return await handler(context);
    return const DialogResult(proceed: true);
  }

  static Future<DialogResult> _handlePowerMenu(BuildContext context) async {
    final result = await PowerMenuDialog.show(context);
    if (result == null) return DialogResult.cancelled;

    final actionName = switch (result.action) {
      PowerAction.shutdown => 'shutdown',
      PowerAction.restart => 'restart',
      PowerAction.sleep => 'sleep',
      PowerAction.hibernate => 'hibernate',
      PowerAction.lock => 'lock',
      PowerAction.cancel => 'cancel',
    };

    final arguments = <String, String>{'action': actionName};
    if (result.minutes != null && result.minutes! > 0) {
      arguments['minutes'] = result.minutes.toString();
    }
    return DialogResult(proceed: true, arguments: arguments);
  }

  static Future<DialogResult> _handleKillProcess(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Завершить процесс',
        subtitle: 'Введите имя процесса',
        icon: Iconsax.close_circle,
        color: const Color(0xFFEC4899),
        fields: [
          const InputFieldConfig(
              key: 'name', label: 'Имя процесса',
              hint: 'Например: chrome.exe', type: InputFieldType.text,
              defaultValue: '', icon: Iconsax.cpu),
        ],
        confirmText: 'Выполнить');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final name = result.values['name']?.toString() ?? '';
    return DialogResult(proceed: true, arguments: name.isNotEmpty ? {'name': name} : null);
  }

  static Future<DialogResult> _handleRecycleBin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderLight),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.warning_2, color: Color(0xFFF59E0B), size: 24),
          ),
          const SizedBox(width: 16),
          const Text('Очистка корзины', style: TextStyle(color: Colors.white)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Вы уверены, что хотите очистить корзину?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Iconsax.info_circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Проверьте, нет ли в корзине нужных файлов.\nВосстановить их после очистки будет невозможно!',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Iconsax.trash, size: 18),
            label: const Text('Очистить корзину'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    return DialogResult(proceed: confirmed ?? false);
  }

  static Future<DialogResult> _handleFindDuplicates(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Поиск дубликатов',
        subtitle: 'Выберите папку для сканирования',
        icon: Iconsax.document_copy,
        color: const Color(0xFFF97316),
        fields: [
          const InputFieldConfig(
              key: 'path', label: 'Папка для сканирования',
              type: InputFieldType.folderPicker, defaultValue: '', icon: Iconsax.folder),
          const InputFieldConfig(
              key: 'min_size', label: 'Мин. размер файла (МБ)',
              type: InputFieldType.number, defaultValue: 1, min: 0, max: 10000,
              icon: Iconsax.weight),
        ],
        confirmText: 'Сканировать');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final path = result.values['path']?.toString() ?? '';
    if (path.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {
      'path': path,
      'min_size': (result.values['min_size'] ?? 1).toString(),
    });
  }

  static Future<DialogResult> _handleSortFiles(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Сортировка файлов',
        subtitle: 'Раскидает файлы по папкам по типу',
        icon: Iconsax.folder_2,
        color: const Color(0xFF22C55E),
        fields: [
          const InputFieldConfig(
              key: 'path', label: 'Папка для сортировки',
              type: InputFieldType.folderPicker, defaultValue: '', icon: Iconsax.folder),
        ],
        confirmText: 'Отсортировать');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final path = result.values['path']?.toString() ?? '';
    if (path.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {'path': path});
  }

  static Future<DialogResult> _handleCleanEmptyFolders(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Очистка пустых папок',
        subtitle: 'Удалит все пустые директории',
        icon: Iconsax.folder_minus,
        color: const Color(0xFF14B8A6),
        fields: [
          const InputFieldConfig(
              key: 'path', label: 'Папка для очистки',
              type: InputFieldType.folderPicker, defaultValue: '', icon: Iconsax.folder),
        ],
        confirmText: 'Очистить');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final path = result.values['path']?.toString() ?? '';
    if (path.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {'path': path});
  }

  static Future<DialogResult> _handleBatchResize(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Пакетный ресайз',
        subtitle: 'Уменьшить все изображения в папке',
        icon: Iconsax.image,
        color: const Color(0xFF06B6D4),
        fields: [
          const InputFieldConfig(
              key: 'path', label: 'Папка с изображениями',
              type: InputFieldType.folderPicker, defaultValue: '', icon: Iconsax.folder),
          const InputFieldConfig(
              key: 'width', label: 'Макс. ширина (px)',
              type: InputFieldType.number, defaultValue: 1920, min: 100, max: 10000,
              icon: Iconsax.arrow_right_1),
          const InputFieldConfig(
              key: 'quality', label: 'Качество (%)',
              type: InputFieldType.number, defaultValue: 85, min: 10, max: 100,
              icon: Iconsax.star),
        ],
        confirmText: 'Уменьшить все');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final path = result.values['path']?.toString() ?? '';
    if (path.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {
      'path': path,
      'width': (result.values['width'] ?? 1920).toString(),
      'quality': (result.values['quality'] ?? 85).toString(),
    });
  }

  static Future<DialogResult> _handleExtractAudio(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Извлечь аудио из видео',
        subtitle: 'Выберите видеофайл',
        icon: Iconsax.music,
        color: const Color(0xFF8B5CF6),
        fields: [
          const InputFieldConfig(
              key: 'input', label: 'Видеофайл',
              type: InputFieldType.filePicker, defaultValue: '',
              icon: Iconsax.video,
              allowedExtensions: ['mp4', 'avi', 'mkv', 'mov', 'webm', 'flv', 'wmv']),
          const InputFieldConfig(
              key: 'format', label: 'Формат аудио',
              type: InputFieldType.dropdown, defaultValue: 'mp3',
              options: ['mp3', 'wav', 'flac', 'aac', 'ogg'], icon: Iconsax.music),
        ],
        confirmText: 'Извлечь');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final input = result.values['input']?.toString() ?? '';
    if (input.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {
      'input': input,
      'format': (result.values['format'] ?? 'mp3').toString(),
    });
  }

  static Future<DialogResult> _handleCreateGif(BuildContext context) async {
    final result = await InputDialog.show(context,
        title: 'Создать GIF',
        subtitle: 'Из видео или папки с картинками',
        icon: Iconsax.gallery,
        color: const Color(0xFFEC4899),
        fields: [
          const InputFieldConfig(
              key: 'input', label: 'Видеофайл или папка',
              type: InputFieldType.filePicker, defaultValue: '',
              icon: Iconsax.video,
              allowedExtensions: ['mp4', 'avi', 'mkv', 'mov', 'webm']),
          const InputFieldConfig(
              key: 'fps', label: 'Кадров в секунду',
              type: InputFieldType.number, defaultValue: 15, min: 5, max: 30,
              icon: Iconsax.timer_1),
          const InputFieldConfig(
              key: 'width', label: 'Ширина (px)',
              type: InputFieldType.number, defaultValue: 480, min: 100, max: 1920,
              icon: Iconsax.arrow_right_1),
        ],
        confirmText: 'Создать GIF');
    if (result == null || !result.confirmed) return DialogResult.cancelled;
    final input = result.values['input']?.toString() ?? '';
    if (input.isEmpty) return DialogResult.cancelled;
    return DialogResult(proceed: true, arguments: {
      'input': input,
      'fps': (result.values['fps'] ?? 15).toString(),
      'width': (result.values['width'] ?? 480).toString(),
    });
  }
}