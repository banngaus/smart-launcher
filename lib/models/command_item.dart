import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CommandItem {
  final String id;
  final String name;
  final String description;
  final String scriptPath;
  final String icon;
  final String category;
  final String color;
  final bool requiresAdmin;
  final bool hasParameters;
  final Map<String, dynamic>? parameters;

  const CommandItem({
    required this.id,
    required this.name,
    required this.description,
    required this.scriptPath,
    this.icon = 'code',
    this.category = 'general',
    this.color = 'blue',
    this.requiresAdmin = false,
    this.hasParameters = false,
    this.parameters,
  });

  CommandItem copyWith({
    String? id,
    String? name,
    String? description,
    String? scriptPath,
    String? icon,
    String? category,
    String? color,
    bool? requiresAdmin,
    bool? hasParameters,
    Map<String, dynamic>? parameters,
  }) {
    return CommandItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scriptPath: scriptPath ?? this.scriptPath,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      color: color ?? this.color,
      requiresAdmin: requiresAdmin ?? this.requiresAdmin,
      hasParameters: hasParameters ?? this.hasParameters,
      parameters: parameters ?? this.parameters,
    );
  }

  factory CommandItem.fromJson(Map<String, dynamic> json) {
    return CommandItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unnamed',
      description: json['description'] ?? '',
      scriptPath: json['script_path'] ?? '',
      icon: json['icon'] ?? 'code',
      category: json['category'] ?? 'general',
      color: json['color'] ?? 'blue',
      requiresAdmin: json['requires_admin'] ?? false,
      hasParameters: json['has_parameters'] ?? false,
      parameters: json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'script_path': scriptPath,
      'icon': icon,
      'category': category,
      'color': color,
      'requires_admin': requiresAdmin,
      'has_parameters': hasParameters,
      if (parameters != null) 'parameters': parameters,
    };
  }

  static const Map<String, IconData> iconMap = {
    'power': Icons.power_settings_new,
    'trash': Iconsax.trash,
    'folder': Iconsax.folder,
    'cpu': Iconsax.cpu,
    'monitor': Iconsax.monitor,
    'wifi': Iconsax.wifi,
    'clock': Iconsax.clock,
    'shield': Iconsax.shield_tick,
    'code': Iconsax.code,
    'setting': Iconsax.setting_2,
    'document': Iconsax.document,
    'refresh': Iconsax.refresh,
    'flash': Iconsax.flash_1,
    'archive': Iconsax.archive_1,
    'close': Iconsax.close_circle,
    'info': Iconsax.info_circle,
    'warning': Iconsax.warning_2,
    'terminal': Iconsax.command_square,
    'disk': Iconsax.driver,
    'memory': Iconsax.ram_2,
    'process': Iconsax.activity,
    'network': Iconsax.global,
    'cancel': Iconsax.close_square,
    'stop': Iconsax.stop,
    'moon': Iconsax.moon,
    'sun': Iconsax.sun_1,
    'timer': Iconsax.timer_1,
    'image': Iconsax.image,
    'music': Iconsax.music,
    'video': Iconsax.video,
    'gallery': Iconsax.gallery,
    'convert': Iconsax.convert,
    'cloud': Iconsax.cloud,
    'lock': Iconsax.lock,
    'mainboard': Iconsax.cpu_setting,
  };

  static const Map<String, Color> colorMap = {
    'blue': Color(0xFF3B82F6),
    'indigo': Color(0xFF6366F1),
    'violet': Color(0xFF8B5CF6),
    'purple': Color(0xFFA855F7),
    'pink': Color(0xFFEC4899),
    'red': Color(0xFFEF4444),
    'orange': Color(0xFFF97316),
    'amber': Color(0xFFF59E0B),
    'green': Color(0xFF22C55E),
    'emerald': Color(0xFF10B981),
    'teal': Color(0xFF14B8A6),
    'cyan': Color(0xFF06B6D4),
  };

  IconData get iconData => iconMap[icon] ?? Iconsax.code;
  Color get colorValue => colorMap[color] ?? const Color(0xFF6366F1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CommandItem(id: $id, name: $name, script: $scriptPath)';
}