import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AppDownloadState {
  final String appName;
  final double progress;
  final String status;
  final bool isDownloading;
  final bool isDone;
  final String? error;

  const AppDownloadState({
    required this.appName,
    this.progress = 0,
    this.status = '',
    this.isDownloading = false,
    this.isDone = false,
    this.error,
  });
}

class AppInstallerService extends ChangeNotifier {
  // Синглтон — живёт пока живёт приложение
  static final AppInstallerService _instance = AppInstallerService._();
  factory AppInstallerService() => _instance;
  AppInstallerService._();

  final Map<String, AppDownloadState> _states = {};
  final Set<String> _installed = {};
  bool _detectedApps = false;

  Map<String, AppDownloadState> get states => Map.unmodifiable(_states);
  Set<String> get installed => Set.unmodifiable(_installed);
  bool get detectedApps => _detectedApps;

  bool isDownloading(String name) =>
      _states[name]?.isDownloading ?? false;

  bool isInstalled(String name) => _installed.contains(name);

  AppDownloadState? getState(String name) => _states[name];

  void markInstalled(String name) {
    _installed.add(name);
    notifyListeners();
  }

  // ═══ Детект установленных приложений ═══
  Future<void> detectInstalledApps(List<(String name, String? regName)> apps) async {
    for (final app in apps) {
      if (app.$2 == null) continue;
      final found = await _isAppInstalled(app.$2!);
      if (found) _installed.add(app.$1);
    }
    _detectedApps = true;
    notifyListeners();
  }

  Future<bool> _isAppInstalled(String name) async {
    const paths = [
      r'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    ];

    for (final path in paths) {
      try {
        final result = await Process.run(
          'reg', ['query', path, '/s', '/f', name, '/d'],
          runInShell: true,
        );
        if (result.exitCode == 0 &&
            result.stdout.toString().toLowerCase().contains(name.toLowerCase())) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // ═══ Скачать и открыть установщик ═══
  Future<void> downloadAndOpen({
    required String name,
    required String url,
  }) async {
    if (isDownloading(name)) return;

    _states[name] = AppDownloadState(
      appName: name,
      isDownloading: true,
      status: 'Подготовка...',
    );
    notifyListeners();

    try {
      // Расширение файла
      String ext = '.exe';
      if (url.toLowerCase().contains('.msi')) ext = '.msi';

      final safeName = name.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final fileName = '${safeName}_setup$ext';
      final savePath = '${Directory.systemTemp.path}\\$fileName';

      // Удаляем старый
      final oldFile = File(savePath);
      if (await oldFile.exists()) await oldFile.delete();

      // Скачиваем
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 60);
      httpClient.userAgent = 'SmartLauncher/1.0';

      final request = await httpClient.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 20;

      final response = await request.close();

      if (response.statusCode >= 400) {
        await response.drain();
        httpClient.close();
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes =
          response.contentLength > 0 ? response.contentLength : 0;
      var receivedBytes = 0;

      final file = File(savePath);
      final sink = file.openWrite();

      _states[name] = AppDownloadState(
        appName: name,
        isDownloading: true,
        status: 'Скачивание...',
      );
      notifyListeners();

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);

        final mb = receivedBytes / 1024 / 1024;
        String statusText;
        double progress = 0;

        if (totalBytes > 0) {
          final totalMb = totalBytes / 1024 / 1024;
          progress = receivedBytes / totalBytes;
          statusText =
              '${mb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB';
        } else {
          statusText = '${mb.toStringAsFixed(1)} MB';
        }

        _states[name] = AppDownloadState(
          appName: name,
          isDownloading: true,
          progress: progress,
          status: statusText,
        );
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      httpClient.close();

      // Проверяем размер
      final fileSize = await file.length();
      if (fileSize < 10240) {
        await file.delete();
        throw Exception('Файл слишком маленький ($fileSize байт)');
      }

      _states[name] = AppDownloadState(
        appName: name,
        isDownloading: true,
        progress: 1.0,
        status: 'Запускаем установщик...',
      );
      notifyListeners();

      // ═══ Запускаем через PowerShell с автоповышением прав ═══
      await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Start-Process -FilePath "$savePath" -Verb RunAs',
        ],
        runInShell: true,
      );

      // Готово
      _installed.add(name);
      _states[name] = AppDownloadState(
        appName: name,
        isDone: true,
        progress: 1.0,
        status: 'Готово!',
      );
      notifyListeners();

      // Убираем статус через 5 секунд
      Future.delayed(const Duration(seconds: 5), () {
        _states.remove(name);
        notifyListeners();
      });
    } catch (e) {
      _states[name] = AppDownloadState(
        appName: name,
        error: e.toString(),
        status: 'Ошибка',
      );
      notifyListeners();

      Future.delayed(const Duration(seconds: 5), () {
        _states.remove(name);
        notifyListeners();
      });
    }
  }
}