import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import '../models/command_item.dart';
import 'config_service.dart';

enum ScriptStatus { idle, running, success, error }

class ScriptOutput {
  final String text;
  final bool isError;
  final DateTime timestamp;

  ScriptOutput({
    required this.text,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ScriptResult {
  final int exitCode;
  final List<ScriptOutput> outputs;
  final Duration duration;
  final ScriptStatus status;

  ScriptResult({
    required this.exitCode,
    required this.outputs,
    required this.duration,
    required this.status,
  });

  bool get isSuccess => exitCode == 0;
}

class ScriptRunner {
  Process? _currentProcess;
  ScriptStatus _status = ScriptStatus.idle;
  bool _disposed = false;

  StreamController<ScriptOutput>? _outputController;
  StreamController<ScriptStatus>? _statusController;

  ScriptStatus get status => _status;
  bool get isRunning => _status == ScriptStatus.running;

  ScriptRunSession createSession() {
    _outputController?.close();
    _statusController?.close();

    _outputController = StreamController<ScriptOutput>.broadcast();
    _statusController = StreamController<ScriptStatus>.broadcast();

    return ScriptRunSession(
      outputStream: _outputController!.stream,
      statusStream: _statusController!.stream,
    );
  }

  void _setStatus(ScriptStatus status) {
    if (_disposed) return;
    _status = status;
    _statusController?.add(status);
  }

  void _addOutput(String text, {bool isError = false}) {
    if (_disposed) return;
    _outputController?.add(ScriptOutput(text: text, isError: isError));
  }

  static void _log(String message) {
    dev.log(message, name: 'ScriptRunner');
  }

  /// Ищет папку с embedded Python
  static Future<String?> _findEmbeddedDir() async {
    // 1. Рядом с exe (Release build)
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final releaseDir = '$exeDir\\python';
    if (await Directory(releaseDir).exists()) {
      return releaseDir;
    }

    // 2. В data папке (installed via CMake)
    final dataDir = '$exeDir\\data\\python';
    if (await Directory(dataDir).exists()) {
      return dataDir;
    }

    // 3. В windows/ (Debug mode, запуск из IDE)
    // Ищем корень проекта — поднимаемся от exe
    Directory current = Directory(exeDir);
    for (int i = 0; i < 6; i++) {
      final candidate = '${current.path}\\windows\\python';
      if (await Directory(candidate).exists()) {
        return candidate;
      }
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }

    // 4. Относительно текущей рабочей директории
    final cwdDir = '${Directory.current.path}\\windows\\python';
    if (await Directory(cwdDir).exists()) {
      return cwdDir;
    }

    return null;
  }

  /// Находит Python — сначала embedded, потом системный
  static Future<String> getPythonPath() async {
    // Embedded Python
    final embeddedDir = await _findEmbeddedDir();
    if (embeddedDir != null) {
      final embeddedPython = '$embeddedDir\\python.exe';
      if (await File(embeddedPython).exists()) {
        _log('Using embedded Python: $embeddedPython');
        return embeddedPython;
      }
    }

    // Системный Python
    for (final cmd in ['python', 'py', 'python3']) {
      try {
        final result = await Process.run(cmd, ['--version']);
        if (result.exitCode == 0) {
          _log('Using system Python: $cmd');
          return cmd;
        }
      } catch (_) {}
    }

    _log('Python not found anywhere!');
    return 'python';
  }

  /// Находит FFmpeg
  static Future<String?> getFFmpegPath() async {
    // Embedded FFmpeg (рядом с Python)
    final embeddedDir = await _findEmbeddedDir();
    if (embeddedDir != null) {
      final embeddedFFmpeg = '$embeddedDir\\ffmpeg.exe';
      if (await File(embeddedFFmpeg).exists()) {
        _log('Using embedded FFmpeg: $embeddedFFmpeg');
        return embeddedFFmpeg;
      }
    }

    // Системный FFmpeg
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        _log('Using system FFmpeg');
        return 'ffmpeg';
      }
    } catch (_) {}

    _log('FFmpeg not found');
    return null;
  }

  /// Формирует environment с правильными путями
  static Future<Map<String, String>> _buildEnvironment() async {
    final env = Map<String, String>.from(Platform.environment);
    env['PYTHONIOENCODING'] = 'utf-8';
    env['PYTHONUNBUFFERED'] = '1';

    final embeddedDir = await _findEmbeddedDir();
    if (embeddedDir != null) {
      // Добавляем embedded Python и его Scripts в PATH
      final scriptsDir = '$embeddedDir\\Scripts';
      final currentPath = env['PATH'] ?? '';
      env['PATH'] = '$embeddedDir;$scriptsDir;$currentPath';

      // Указываем Python где искать пакеты
      final libDir = '$embeddedDir\\Lib';
      final sitePackages = '$libDir\\site-packages';
      if (await Directory(sitePackages).exists()) {
        env['PYTHONPATH'] = sitePackages;
      }
    }

    return env;
  }

  Future<ScriptResult> runScript(
    CommandItem command, {
    Map<String, String>? arguments,
  }) async {
    if (_disposed) {
      return ScriptResult(
        exitCode: -1,
        outputs: [],
        duration: Duration.zero,
        status: ScriptStatus.error,
      );
    }

    await stopScript();

    final outputs = <ScriptOutput>[];
    final stopwatch = Stopwatch()..start();

    try {
      _setStatus(ScriptStatus.running);

      _addOutput('═' * 50);
      _addOutput('▶ Запуск: ${command.name}');
      _addOutput('  Скрипт: ${command.scriptPath}');
      if (arguments != null && arguments.isNotEmpty) {
        _addOutput('  Аргументы: $arguments');
      }
      _addOutput('═' * 50);
      _addOutput('');

      // Python
      final pythonPath = await getPythonPath();
      final isEmbedded = !(pythonPath == 'python' ||
          pythonPath == 'py' ||
          pythonPath == 'python3');
      _addOutput('[INFO] Python: $pythonPath');
      _addOutput('[INFO] Тип: ${isEmbedded ? "Embedded" : "Системный"}');

      // FFmpeg
      final ffmpegPath = await getFFmpegPath();
      if (ffmpegPath != null) {
        _addOutput('[INFO] FFmpeg: $ffmpegPath');
      }
      _addOutput('');

      // Путь к скрипту
      final scriptsDir = await ConfigService.getScriptsDirectory();
      final scriptPath = '${scriptsDir.path}/${command.scriptPath}';

      // Проверяем и восстанавливаем скрипт
      if (!await File(scriptPath).exists()) {
        if (ConfigService.isBuiltInScript(command.scriptPath)) {
          _addOutput('[...] Восстановление встроенного скрипта...');
          await ConfigService.restoreBuiltInScript(command.scriptPath);

          if (!await File(scriptPath).exists()) {
            throw Exception(
                'Скрипт не найден после восстановления: $scriptPath');
          }
          _addOutput('[OK] Скрипт восстановлен');
          _addOutput('');
        } else {
          throw Exception('Скрипт не найден: $scriptPath');
        }
      }

      // Аргументы
      final args = <String>[scriptPath];
      if (arguments != null) {
        arguments.forEach((key, value) {
          if (value.isNotEmpty) {
            args.add('--$key=$value');
          } else {
            args.add('--$key');
          }
        });
      }

      _log('Running: $pythonPath ${args.join(' ')}');

      // Environment
      final env = await _buildEnvironment();

      // Запуск
      _currentProcess = await Process.start(
        pythonPath,
        args,
        runInShell: true,
        workingDirectory: scriptsDir.path,
        environment: env,
      );

      // stdout
      final stdoutCompleter = Completer<void>();
      _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          outputs.add(ScriptOutput(text: line));
          _addOutput(line);
        },
        onDone: () => stdoutCompleter.complete(),
        onError: (e) => stdoutCompleter.complete(),
      );

      // stderr
      final stderrCompleter = Completer<void>();
      _currentProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          outputs.add(ScriptOutput(text: line, isError: true));
          _addOutput(line, isError: true);
        },
        onDone: () => stderrCompleter.complete(),
        onError: (e) => stderrCompleter.complete(),
      );

      // Ждём завершения
      final exitCode = await _currentProcess!.exitCode;

      await Future.wait([
        stdoutCompleter.future,
        stderrCompleter.future,
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [null, null],
      );

      stopwatch.stop();
      _currentProcess = null;

      final resultStatus =
          exitCode == 0 ? ScriptStatus.success : ScriptStatus.error;
      _setStatus(resultStatus);

      _addOutput('');
      _addOutput('═' * 50);
      if (exitCode == 0) {
        _addOutput('✓ Завершено за ${_formatDuration(stopwatch.elapsed)}');
      } else {
        _addOutput('✗ Код выхода: $exitCode', isError: true);
      }
      _addOutput('═' * 50);

      return ScriptResult(
        exitCode: exitCode,
        outputs: outputs,
        duration: stopwatch.elapsed,
        status: resultStatus,
      );
    } catch (e) {
      stopwatch.stop();
      _currentProcess = null;
      _setStatus(ScriptStatus.error);

      final errorMsg = '✗ Ошибка: $e';
      outputs.add(ScriptOutput(text: errorMsg, isError: true));
      _addOutput(errorMsg, isError: true);

      _log('Script error: $e');

      return ScriptResult(
        exitCode: -1,
        outputs: outputs,
        duration: stopwatch.elapsed,
        status: ScriptStatus.error,
      );
    }
  }

  Future<void> stopScript() async {
    if (_currentProcess != null) {
      _currentProcess!.kill(ProcessSignal.sigterm);
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        _currentProcess?.kill(ProcessSignal.sigkill);
      } catch (_) {}

      _currentProcess = null;
      _addOutput('');
      _addOutput('⚠ Скрипт остановлен пользователем', isError: true);
      _setStatus(ScriptStatus.idle);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 1) {
      return '${d.inMilliseconds}мс';
    } else if (d.inMinutes < 1) {
      return '${d.inSeconds}.${(d.inMilliseconds % 1000) ~/ 100}с';
    } else {
      return '${d.inMinutes}м ${d.inSeconds % 60}с';
    }
  }

  static Future<bool> checkPythonInstalled() async {
    try {
      final pythonPath = await getPythonPath();
      final result = await Process.run(pythonPath, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getPythonVersion() async {
    try {
      final pythonPath = await getPythonPath();
      final env = await _buildEnvironment();
      final result =
          await Process.run(pythonPath, ['--version'], environment: env);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      _log('Python version check failed: $e');
    }
    return null;
  }

  static Future<String?> getFFmpegVersion() async {
    try {
      final ffmpegPath = await getFFmpegPath();
      if (ffmpegPath == null) return null;

      final result = await Process.run(ffmpegPath, ['-version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Берём только "ffmpeg version N.N.N"
        final match =
            RegExp(r'ffmpeg version (\S+)').firstMatch(output);
        if (match != null) {
          return 'FFmpeg ${match.group(1)}';
        }
        return output.split('\n').first.trim();
      }
    } catch (e) {
      _log('FFmpeg version check failed: $e');
    }
    return null;
  }

  void dispose() {
    _disposed = true;
    _currentProcess?.kill();
    _currentProcess = null;
    _outputController?.close();
    _statusController?.close();
  }
}

class ScriptRunSession {
  final Stream<ScriptOutput> outputStream;
  final Stream<ScriptStatus> statusStream;

  const ScriptRunSession({
    required this.outputStream,
    required this.statusStream,
  });
}