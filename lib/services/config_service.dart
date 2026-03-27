import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/command_item.dart';

class ConfigService {
  static const String _configFileName = 'commands.json';
  static const String _appFolderName = 'SmartLauncher';

  static const int _configVersion = 3;
  static const String _versionFileName = 'config_version';

  static const List<String> _builtInScripts = [
    'power_manager.py',
    'clean_temp.py',
    'empty_recycle_bin.py',
    'kill_process.py',
    'flush_dns.py',
    'convert_file.py',
    'find_duplicates.py',
    'sort_files.py',
    'clean_empty_folders.py',
    'batch_resize.py',
    'extract_audio.py',
    'create_gif.py',
    'system_monitor.py',
  ];

  static const List<String> _deprecatedScripts = [
    'shutdown_timer.py',
    'cancel_shutdown.py',
    'sleep_pc.py',
  ];

  static void _log(String message) {
    dev.log(message, name: 'ConfigService');
  }

  static Future<Directory> getAppDirectory() async {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) {
      throw Exception('Не удалось найти папку APPDATA');
    }

    final appDir = Directory('$appData/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
      _log('Created app directory: ${appDir.path}');
    }

    return appDir;
  }

  static Future<Directory> getScriptsDirectory() async {
    final appDir = await getAppDirectory();
    final scriptsDir = Directory('${appDir.path}/scripts');

    if (!await scriptsDir.exists()) {
      await scriptsDir.create(recursive: true);
    }

    await _ensureBuiltInScripts(scriptsDir);
    return scriptsDir;
  }

  static Future<int> _getSavedConfigVersion() async {
    try {
      final appDir = await getAppDirectory();
      final versionFile = File('${appDir.path}/$_versionFileName');
      if (await versionFile.exists()) {
        final content = await versionFile.readAsString();
        return int.tryParse(content.trim()) ?? 0;
      }
    } catch (e) {
      _log('Error reading config version: $e');
    }
    return 0;
  }

  static Future<void> _saveConfigVersion(int version) async {
    try {
      final appDir = await getAppDirectory();
      final versionFile = File('${appDir.path}/$_versionFileName');
      await versionFile.writeAsString(version.toString());
      _log('Config version saved: $version');
    } catch (e) {
      _log('Error saving config version: $e');
    }
  }

  static Future<bool> _needsMigration() async {
    final savedVersion = await _getSavedConfigVersion();
    return savedVersion < _configVersion;
  }

  static Future<void> _performMigration() async {
    final savedVersion = await _getSavedConfigVersion();
    _log('Migrating config from v$savedVersion to v$_configVersion');

    try {
      final appDir = await getAppDirectory();
      final scriptsDir = Directory('${appDir.path}/scripts');

      if (await scriptsDir.exists()) {
        for (final oldScript in _deprecatedScripts) {
          final oldFile = File('${scriptsDir.path}/$oldScript');
          if (await oldFile.exists()) {
            await oldFile.delete();
            _log('Deleted deprecated script: $oldScript');
          }
        }
      }

      final configFile = await _getConfigFile();
      if (await configFile.exists()) {
        final backupPath = '${configFile.path}.v$savedVersion.backup';
        await configFile.copy(backupPath);
        _log('Old config backed up to: $backupPath');
      }

      List<CommandItem> userCommands = [];
      try {
        if (await configFile.exists()) {
          final contents = await configFile.readAsString();
          if (contents.trim().isNotEmpty) {
            final List<dynamic> jsonList = json.decode(contents);
            final allOldCommands =
                jsonList.map((e) => CommandItem.fromJson(e)).toList();

            final allKnownScripts = <String>[
              ..._builtInScripts,
              ..._deprecatedScripts,
            ];

            userCommands = allOldCommands
                .where((cmd) => !allKnownScripts.contains(cmd.scriptPath))
                .toList();

            if (userCommands.isNotEmpty) {
              _log('Preserved ${userCommands.length} user commands');
            }
          }
        }
      } catch (e) {
        _log('Error reading old commands during migration: $e');
      }

      final newCommands = <CommandItem>[
        ..._getDefaultCommands(),
        ...userCommands,
      ];
      await saveCommands(newCommands);

      if (await scriptsDir.exists()) {
        for (final scriptName in _builtInScripts) {
          final scriptFile = File('${scriptsDir.path}/$scriptName');
          await _copyBuiltInScript(scriptName, scriptFile);
        }
      }

      await _saveConfigVersion(_configVersion);
      _log('Migration complete to v$_configVersion');
    } catch (e) {
      _log('Migration error: $e');
      await _saveConfigVersion(_configVersion);
    }
  }

  static Future<void> _ensureBuiltInScripts(Directory scriptsDir) async {
    for (final scriptName in _builtInScripts) {
      final scriptFile = File('${scriptsDir.path}/$scriptName');
      if (!await scriptFile.exists()) {
        await _copyBuiltInScript(scriptName, scriptFile);
      }
    }
  }

  static Future<void> _copyBuiltInScript(
      String scriptName, File targetFile) async {
    try {
      final scriptContent =
          await rootBundle.loadString('assets/scripts/$scriptName');
      await targetFile.writeAsString(scriptContent);
      _log('Copied script: $scriptName');
    } catch (e) {
      _log('Failed to copy $scriptName: $e');
    }
  }

  static Future<bool> restoreBuiltInScript(String scriptName) async {
    if (!_builtInScripts.contains(scriptName)) return false;

    final scriptsDir = await getScriptsDirectory();
    final scriptFile = File('${scriptsDir.path}/$scriptName');
    await _copyBuiltInScript(scriptName, scriptFile);
    return await scriptFile.exists();
  }

  static Future<void> restoreAllBuiltInScripts() async {
    final scriptsDir = await getScriptsDirectory();
    for (final scriptName in _builtInScripts) {
      final scriptFile = File('${scriptsDir.path}/$scriptName');
      await _copyBuiltInScript(scriptName, scriptFile);
    }
    _log('All built-in scripts restored');
  }

  static bool isBuiltInScript(String scriptName) {
    return _builtInScripts.contains(scriptName);
  }

  static Future<String?> addUserScript(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final scriptsDir = await getScriptsDirectory();
      final fileName = sourceFile.uri.pathSegments.last;

      var targetFileName = fileName;
      var counter = 1;
      while (await File('${scriptsDir.path}/$targetFileName').exists()) {
        final ext =
            fileName.contains('.') ? '.${fileName.split('.').last}' : '';
        final baseName = fileName.replaceAll(ext, '');
        targetFileName = '${baseName}_$counter$ext';
        counter++;
      }

      final targetFile = File('${scriptsDir.path}/$targetFileName');
      await sourceFile.copy(targetFile.path);
      _log('Script added: $targetFileName');
      return targetFileName;
    } catch (e) {
      _log('Error adding script: $e');
      return null;
    }
  }

  static Future<bool> deleteUserScript(String scriptName) async {
    if (isBuiltInScript(scriptName)) return false;

    try {
      final scriptsDir = await getScriptsDirectory();
      final scriptFile = File('${scriptsDir.path}/$scriptName');
      if (await scriptFile.exists()) {
        await scriptFile.delete();
        _log('Script deleted: $scriptName');
        return true;
      }
      return false;
    } catch (e) {
      _log('Error deleting script: $e');
      return false;
    }
  }

  static Future<File> _getConfigFile() async {
    final appDir = await getAppDirectory();
    return File('${appDir.path}/$_configFileName');
  }

  static Future<List<CommandItem>> loadCommands() async {
    try {
      if (await _needsMigration()) {
        await _performMigration();
      }

      await getScriptsDirectory();
      final file = await _getConfigFile();

      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.trim().isEmpty) {
          _log('Config file is empty, using defaults');
          final defaults = _getDefaultCommands();
          await saveCommands(defaults);
          await _saveConfigVersion(_configVersion);
          return defaults;
        }

        final List<dynamic> jsonList = json.decode(contents);
        return jsonList.map((e) => CommandItem.fromJson(e)).toList();
      } else {
        final defaultCommands = _getDefaultCommands();
        await saveCommands(defaultCommands);
        await _saveConfigVersion(_configVersion);
        return defaultCommands;
      }
    } on FormatException catch (e) {
      _log('Corrupted config file: $e');
      try {
        final file = await _getConfigFile();
        if (await file.exists()) {
          final backupPath =
              '${file.path}.backup.${DateTime.now().millisecondsSinceEpoch}';
          await file.copy(backupPath);
        }
      } catch (_) {}

      final defaults = _getDefaultCommands();
      await saveCommands(defaults);
      await _saveConfigVersion(_configVersion);
      return defaults;
    } catch (e) {
      _log('Error loading commands: $e');
      return _getDefaultCommands();
    }
  }

  static Future<void> saveCommands(List<CommandItem> commands) async {
    try {
      final file = await _getConfigFile();
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(commands.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
      _log('Config saved (${commands.length} commands)');
    } catch (e) {
      _log('Error saving config: $e');
    }
  }

  static Future<void> addCommand(CommandItem command) async {
    final commands = await loadCommands();
    commands.add(command);
    await saveCommands(commands);
  }

  static Future<void> removeCommand(String id,
      {bool deleteScript = false}) async {
    final commands = await loadCommands();
    final commandIndex = commands.indexWhere((c) => c.id == id);

    if (commandIndex != -1) {
      final command = commands[commandIndex];
      if (deleteScript && !isBuiltInScript(command.scriptPath)) {
        await deleteUserScript(command.scriptPath);
      }
      commands.removeAt(commandIndex);
      await saveCommands(commands);
    }
  }

  static Future<void> updateCommand(CommandItem command) async {
    final commands = await loadCommands();
    final index = commands.indexWhere((c) => c.id == command.id);
    if (index != -1) {
      commands[index] = command;
      await saveCommands(commands);
    }
  }

  static Future<bool> scriptExists(String scriptName) async {
    final scriptsDir = await getScriptsDirectory();
    final scriptFile = File('${scriptsDir.path}/$scriptName');
    return scriptFile.exists();
  }

  static Future<void> openScriptsFolder() async {
    final scriptsDir = await getScriptsDirectory();
    await Process.run('explorer', [scriptsDir.path]);
  }

  static Future<void> openAppFolder() async {
    final appDir = await getAppDirectory();
    await Process.run('explorer', [appDir.path]);
  }

  static Future<void> resetToDefaults() async {
    final defaults = _getDefaultCommands();
    await saveCommands(defaults);
    await restoreAllBuiltInScripts();
    await _saveConfigVersion(_configVersion);
    _log('Reset to defaults complete');
  }

  static List<CommandItem> _getDefaultCommands() {
    return const [
      // ═══ ПИТАНИЕ ═══
      CommandItem(
        id: '1',
        name: 'Управление питанием',
        description: 'Выключение, перезагрузка, сон, гибернация',
        scriptPath: 'power_manager.py',
        icon: 'power',
        category: 'power',
        color: 'red',
        hasParameters: true,
      ),

      // ═══ ОЧИСТКА ═══
      CommandItem(
        id: '3',
        name: 'Очистка TEMP',
        description: 'Удалить временные файлы системы',
        scriptPath: 'clean_temp.py',
        icon: 'trash',
        category: 'cleanup',
        color: 'orange',
        requiresAdmin: true,
      ),
      CommandItem(
        id: '5',
        name: 'Очистка корзины',
        description: 'Полностью очистить корзину',
        scriptPath: 'empty_recycle_bin.py',
        icon: 'archive',
        category: 'cleanup',
        color: 'amber',
        hasParameters: true,
      ),

      // ═══ СИСТЕМА ═══
      CommandItem(
        id: '6',
        name: 'Убить процесс',
        description: 'Завершить выбранный процесс',
        scriptPath: 'kill_process.py',
        icon: 'close',
        category: 'system',
        color: 'pink',
        hasParameters: true,
      ),

      // ═══ СЕТЬ ═══
      CommandItem(
        id: '7',
        name: 'Очистка DNS',
        description: 'Сбросить кэш DNS',
        scriptPath: 'flush_dns.py',
        icon: 'network',
        category: 'network',
        color: 'cyan',
        requiresAdmin: true,
      ),

      // ═══ ФАЙЛЫ ═══
      CommandItem(
        id: '12',
        name: 'Сортировка файлов',
        description: 'Раскидать файлы по папкам по типу',
        scriptPath: 'sort_files.py',
        icon: 'folder',
        category: 'files',
        color: 'green',
        hasParameters: true,
      ),

      // ═══ МЕДИА ═══
      CommandItem(
        id: '13',
        name: 'Пакетный ресайз',
        description: 'Уменьшить все изображения в папке',
        scriptPath: 'batch_resize.py',
        icon: 'image',
        category: 'media',
        color: 'cyan',
        hasParameters: true,
      ),
      CommandItem(
        id: '14',
        name: 'Извлечь аудио',
        description: 'Извлечь аудиодорожку из видео',
        scriptPath: 'extract_audio.py',
        icon: 'music',
        category: 'media',
        color: 'violet',
        hasParameters: true,
      ),
      CommandItem(
        id: '16',
        name: 'Создать GIF',
        description: 'Из видео или набора изображений',
        scriptPath: 'create_gif.py',
        icon: 'flash',
        category: 'media',
        color: 'pink',
        hasParameters: true,
      ),
    ];
  }
}