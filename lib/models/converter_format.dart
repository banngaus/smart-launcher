import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum FileCategory { image, audio, video, document }

class ConversionFormat {
  final String extension;
  final String name;
  final FileCategory category;
  final List<String> canConvertTo;

  const ConversionFormat({
    required this.extension,
    required this.name,
    required this.category,
    required this.canConvertTo,
  });

  IconData get icon {
    return switch (category) {
      FileCategory.image => Iconsax.image,
      FileCategory.audio => Iconsax.music,
      FileCategory.video => Iconsax.video,
      FileCategory.document => Iconsax.document,
    };
  }

  Color get color {
    return switch (category) {
      FileCategory.image => const Color(0xFF22C55E),
      FileCategory.audio => const Color(0xFF8B5CF6),
      FileCategory.video => const Color(0xFFEF4444),
      FileCategory.document => const Color(0xFF3B82F6),
    };
  }

  String get categoryName {
    return switch (category) {
      FileCategory.image => 'Изображения',
      FileCategory.audio => 'Аудио',
      FileCategory.video => 'Видео',
      FileCategory.document => 'Документы',
    };
  }
}

class ConversionFormats {
  static const List<ConversionFormat> all = [
    // ═══ ИЗОБРАЖЕНИЯ ═══
    ConversionFormat(
      extension: 'png',
      name: 'PNG',
      category: FileCategory.image,
      canConvertTo: ['jpg', 'jpeg', 'webp', 'bmp', 'ico', 'tiff'],
    ),
    ConversionFormat(
      extension: 'jpg',
      name: 'JPEG',
      category: FileCategory.image,
      canConvertTo: ['png', 'webp', 'bmp', 'ico', 'tiff'],
    ),
    ConversionFormat(
      extension: 'jpeg',
      name: 'JPEG',
      category: FileCategory.image,
      canConvertTo: ['png', 'webp', 'bmp', 'ico', 'tiff'],
    ),
    ConversionFormat(
      extension: 'webp',
      name: 'WebP',
      category: FileCategory.image,
      canConvertTo: ['png', 'jpg', 'bmp', 'ico', 'tiff'],
    ),
    ConversionFormat(
      extension: 'bmp',
      name: 'BMP',
      category: FileCategory.image,
      canConvertTo: ['png', 'jpg', 'webp', 'ico', 'tiff'],
    ),
    ConversionFormat(
      extension: 'tiff',
      name: 'TIFF',
      category: FileCategory.image,
      canConvertTo: ['png', 'jpg', 'webp', 'bmp'],
    ),
    ConversionFormat(
      extension: 'ico',
      name: 'ICO',
      category: FileCategory.image,
      canConvertTo: ['png', 'jpg', 'bmp'],
    ),

    // ═══ АУДИО ═══
    ConversionFormat(
      extension: 'mp3',
      name: 'MP3',
      category: FileCategory.audio,
      canConvertTo: ['wav', 'flac', 'ogg', 'aac', 'm4a', 'wma'],
    ),
    ConversionFormat(
      extension: 'wav',
      name: 'WAV',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'flac', 'ogg', 'aac', 'm4a'],
    ),
    ConversionFormat(
      extension: 'flac',
      name: 'FLAC',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'wav', 'ogg', 'aac', 'm4a'],
    ),
    ConversionFormat(
      extension: 'ogg',
      name: 'OGG',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'wav', 'flac', 'aac'],
    ),
    ConversionFormat(
      extension: 'aac',
      name: 'AAC',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'wav', 'flac', 'ogg'],
    ),
    ConversionFormat(
      extension: 'm4a',
      name: 'M4A',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'wav', 'flac', 'ogg'],
    ),
    ConversionFormat(
      extension: 'wma',
      name: 'WMA',
      category: FileCategory.audio,
      canConvertTo: ['mp3', 'wav', 'flac'],
    ),

    // ═══ ВИДЕО ═══
    ConversionFormat(
      extension: 'mp4',
      name: 'MP4',
      category: FileCategory.video,
      canConvertTo: ['avi', 'mkv', 'mov', 'webm', 'gif'],
    ),
    ConversionFormat(
      extension: 'avi',
      name: 'AVI',
      category: FileCategory.video,
      canConvertTo: ['mp4', 'mkv', 'mov', 'webm'],
    ),
    ConversionFormat(
      extension: 'mkv',
      name: 'MKV',
      category: FileCategory.video,
      canConvertTo: ['mp4', 'avi', 'mov', 'webm'],
    ),
    ConversionFormat(
      extension: 'mov',
      name: 'MOV',
      category: FileCategory.video,
      canConvertTo: ['mp4', 'avi', 'mkv', 'webm', 'gif'],
    ),
    ConversionFormat(
      extension: 'webm',
      name: 'WebM',
      category: FileCategory.video,
      canConvertTo: ['mp4', 'avi', 'mkv', 'mov'],
    ),
    ConversionFormat(
      extension: 'gif',
      name: 'GIF',
      category: FileCategory.video,
      canConvertTo: ['mp4', 'webm'],
    ),
  ];

  static ConversionFormat? findByExtension(String ext) {
    final lower = ext.toLowerCase().replaceAll('.', '');
    try {
      return all.firstWhere((f) => f.extension == lower);
    } catch (_) {
      return null;
    }
  }

  static List<ConversionFormat> byCategory(FileCategory category) {
    return all.where((f) => f.category == category).toList();
  }
}