import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../models/command_item.dart';
import '../models/converter_format.dart';
import '../services/converter_service.dart';
import '../services/script_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/log_modal.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  FileCategory _selectedCategory = FileCategory.image;
  final List<_ConversionItem> _items = [];
  String? _targetFormat;
  int _quality = 85;
  bool _isDragOver = false;
  final ScriptRunner _scriptRunner = ScriptRunner();

  @override
  void dispose() {
    _scriptRunner.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final extensions = ConversionFormats.byCategory(_selectedCategory)
        .map((f) => f.extension)
        .toList();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: extensions,
      dialogTitle: 'Выберите файлы для конвертации',
    );

    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            final format = ConversionFormats.findByExtension(
                file.path!.split('.').last);
            if (format != null) {
              _items.add(_ConversionItem(
                path: file.path!,
                name: file.name,
                size: file.size,
                sourceFormat: format,
              ));
            }
          }
        }

        // Автовыбор целевого формата
        if (_targetFormat == null && _items.isNotEmpty) {
          final targets = _items.first.sourceFormat.canConvertTo;
          if (targets.isNotEmpty) {
            _targetFormat = targets.first;
          }
        }
      });
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _clearAll() {
    setState(() {
      _items.clear();
      _targetFormat = null;
    });
  }

  Future<void> _convertAll() async {
    if (_items.isEmpty || _targetFormat == null) return;

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.status == _ConversionStatus.success) continue;

      final outputPath = ConverterService.generateOutputPath(
          item.path, _targetFormat!);

      setState(() {
        item.status = _ConversionStatus.running;
        item.outputPath = outputPath;
      });

      // Создаём виртуальную CommandItem для запуска скрипта
      final command = CommandItem(
        id: 'convert_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Конвертация: ${item.name}',
        description: '${item.sourceFormat.extension} → $_targetFormat',
        scriptPath: 'convert_file.py',
        icon: 'refresh',
        category: 'converter',
        color: 'green',
      );

      final session = _scriptRunner.createSession();

      // Слушаем результат
      ScriptStatus? finalStatus;
      final statusSub = session.statusStream.listen((status) {
        finalStatus = status;
      });

      await _scriptRunner.runScript(
        command,
        arguments: {
          'input': item.path,
          'output': outputPath,
          'quality': _quality.toString(),
        },
      );

      await statusSub.cancel();

      setState(() {
        if (finalStatus == ScriptStatus.success) {
          item.status = _ConversionStatus.success;
          // Обновляем размер выходного файла
          final outFile = File(outputPath);
          if (outFile.existsSync()) {
            item.outputSize = outFile.lengthSync();
          }
        } else {
          item.status = _ConversionStatus.error;
        }
      });
    }
  }

  Future<void> _convertSingle(int index) async {
    if (_targetFormat == null) return;

    final item = _items[index];
    final outputPath =
        ConverterService.generateOutputPath(item.path, _targetFormat!);

    final command = CommandItem(
      id: 'convert_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Конвертация: ${item.name}',
      description: '${item.sourceFormat.extension} → $_targetFormat',
      scriptPath: 'convert_file.py',
      icon: 'refresh',
      category: 'converter',
      color: 'green',
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogModal(
        command: command,
        scriptRunner: _scriptRunner,
        arguments: {
          'input': item.path,
          'output': outputPath,
          'quality': _quality.toString(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final successCount =
        _items.where((i) => i.status == _ConversionStatus.success).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Конвертер файлов',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _items.isEmpty
                    ? 'Добавьте файлы для конвертации'
                    : '${_items.length} файлов • $successCount завершено',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          if (_items.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Iconsax.trash, size: 18),
              label: const Text('Очистить'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Iconsax.add, size: 20),
            label: const Text('Добавить файлы'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final categories = [
      (FileCategory.image, 'Изображения', Iconsax.image, const Color(0xFF22C55E)),
      (FileCategory.audio, 'Аудио', Iconsax.music, const Color(0xFF8B5CF6)),
      (FileCategory.video, 'Видео', Iconsax.video, const Color(0xFFEF4444)),
    ];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ТИП ФАЙЛОВ',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...categories.map((cat) {
            final isSelected = _selectedCategory == cat.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat.$1;
                      _targetFormat = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.$4.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? cat.$4.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat.$3,
                            size: 20,
                            color: isSelected ? cat.$4 : AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          cat.$2,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Target format selector
          if (_items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'КОНВЕРТИРОВАТЬ В',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTargetFormatSelector(),
            const SizedBox(height: 24),

            // Quality slider
            _buildQualitySlider(),
          ],

          const Spacer(),

          // Convert all button
          if (_items.isNotEmpty && _targetFormat != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _convertAll,
                icon: const Icon(Iconsax.convert, size: 20),
                label: const Text('Конвертировать всё'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTargetFormatSelector() {
    // Собираем все доступные целевые форматы
    Set<String> availableTargets = {};
    for (final item in _items) {
      availableTargets.addAll(item.sourceFormat.canConvertTo);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: availableTargets.map((format) {
          final isSelected = _targetFormat == format;
          final formatInfo = ConversionFormats.findByExtension(format);
          final color = formatInfo?.color ?? AppTheme.primaryColor;

          return GestureDetector(
            onTap: () => setState(() => _targetFormat = format),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.5)
                      : AppTheme.borderLight,
                ),
              ),
              child: Text(
                format.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQualitySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'КАЧЕСТВО',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _quality.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    onChanged: (v) => setState(() => _quality = v.round()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_quality%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return _buildDropZone();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _buildFileItem(_items[index], index)
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            )
            .slideX(
              begin: 0.05,
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            );
      },
    );
  }

  Widget _buildDropZone() {
    return Center(
      child: GestureDetector(
        onTap: _pickFiles,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: _isDragOver
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.bgCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDragOver
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : AppTheme.borderLight,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.document_upload,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Нажмите чтобы выбрать файлы',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Поддерживаются: ${_getSupportedFormatsText()}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSupportedFormatsText() {
    final formats = ConversionFormats.byCategory(_selectedCategory);
    return formats.map((f) => f.extension.toUpperCase()).join(', ');
  }

  Widget _buildFileItem(_ConversionItem item, int index) {
    final color = item.sourceFormat.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == _ConversionStatus.success
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : item.status == _ConversionStatus.error
                  ? AppTheme.errorColor.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.sourceFormat.icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildFormatBadge(
                        item.sourceFormat.extension.toUpperCase(), color),
                    if (_targetFormat != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Iconsax.arrow_right_3,
                            color: AppTheme.textMuted, size: 14),
                      ),
                      _buildFormatBadge(
                        _targetFormat!.toUpperCase(),
                        const Color(0xFF22C55E),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Text(
                      _formatFileSize(item.size),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (item.outputSize != null) ...[
                      const Text(' → ',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      Text(
                        _formatFileSize(item.outputSize!),
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status / Actions
          if (item.status == _ConversionStatus.running)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.accentColor),
            )
          else if (item.status == _ConversionStatus.success)
            const Icon(Iconsax.tick_circle,
                color: Color(0xFF22C55E), size: 24)
          else if (item.status == _ConversionStatus.error)
            const Icon(Iconsax.close_circle,
                color: AppTheme.errorColor, size: 24)
          else ...[
            if (_targetFormat != null)
              IconButton(
                onPressed: () => _convertSingle(index),
                icon: const Icon(Iconsax.play, size: 20),
                tooltip: 'Конвертировать',
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF22C55E),
                  backgroundColor:
                      const Color(0xFF22C55E).withValues(alpha: 0.1),
                ),
              ),
            IconButton(
              onPressed: () => _removeItem(index),
              icon: const Icon(Iconsax.trash, size: 18),
              tooltip: 'Удалить',
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }
}

class _ConversionItem {
  final String path;
  final String name;
  final int size;
  final ConversionFormat sourceFormat;
  _ConversionStatus status;
  String? outputPath;
  int? outputSize;

  _ConversionItem({
    required this.path,
    required this.name,
    required this.size,
    required this.sourceFormat,
    this.status = _ConversionStatus.pending,
  });
}

enum _ConversionStatus { pending, running, success, error }