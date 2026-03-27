import 'dart:io';

import '../models/converter_format.dart';
import 'script_runner.dart';
import 'config_service.dart';

class ConversionTask {
  final String inputPath;
  final String outputPath;
  final String fromFormat;
  final String toFormat;
  final int? quality;
  final DateTime startTime;
  ConversionStatus status;
  String? error;
  double? progress;

  ConversionTask({
    required this.inputPath,
    required this.outputPath,
    required this.fromFormat,
    required this.toFormat,
    this.quality,
    this.status = ConversionStatus.pending,
    this.error,
  }) : startTime = DateTime.now();

  String get inputFileName => File(inputPath).uri.pathSegments.last;
  String get outputFileName => File(outputPath).uri.pathSegments.last;
}

enum ConversionStatus { pending, running, success, error }

class ConverterService {
  /// Генерирует выходной путь на основе входного и целевого формата
  static String generateOutputPath(String inputPath, String targetFormat) {
    final file = File(inputPath);
    final dir = file.parent.path;
    final name = file.uri.pathSegments.last;
    final baseName = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;

    var outputPath = '$dir/$baseName.$targetFormat';

    // Если файл уже существует, добавляем суффикс
    var counter = 1;
    while (File(outputPath).existsSync()) {
      outputPath = '$dir/${baseName}_converted_$counter.$targetFormat';
      counter++;
    }

    return outputPath;
  }

  /// Определяет категорию файла по расширению
  static FileCategory? detectCategory(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    final format = ConversionFormats.findByExtension(ext);
    return format?.category;
  }

  /// Возвращает доступные форматы для конвертации
  static List<String> getAvailableTargets(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    final format = ConversionFormats.findByExtension(ext);
    return format?.canConvertTo ?? [];
  }

  /// Проверяет доступность инструментов
  static Future<Map<String, bool>> checkTools() async {
    final python = await ScriptRunner.checkPythonInstalled();
    final ffmpeg = await ScriptRunner.getFFmpegPath() != null;

    return {
      'python': python,
      'ffmpeg': ffmpeg,
      'pillow': python,
    };
  }
}