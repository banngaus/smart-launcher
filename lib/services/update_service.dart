import 'dart:convert';
import 'dart:io';

/// Информация об обновлении
class UpdateInfo {
  final String version;
  final String currentVersion;
  final String downloadUrl;
  final String fileName;
  final String changelog;
  final int size;
  final String? publishedAt;

  UpdateInfo({
    required this.version,
    required this.currentVersion,
    required this.downloadUrl,
    required this.fileName,
    required this.changelog,
    required this.size,
    this.publishedAt,
  });
}

class UpdateService {
  // ══════════════════════════════════════════════
  // ⚙️ НАСТРОЙ ЭТО ПОД СЕБЯ
  // ══════════════════════════════════════════════
  static const String currentVersion = '1.0.0';
  static const String githubOwner = 'banngaus';
  static const String githubRepo = 'https://github.com/banngaus/smart-launcher.git';
  static const String exeName = 'smart_launcher.exe';
  // ══════════════════════════════════════════════

  /// Проверить наличие обновления
  static Future<UpdateInfo?> checkForUpdate() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(
        Uri.parse(
          'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
        ),
      );
      request.headers.set('User-Agent', 'SmartLauncher-Updater');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();

      if (response.statusCode != 200) {
        await response.drain();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceAll(RegExp(r'^v'), '');

      if (!_isNewer(latestVersion, currentVersion)) return null;

      final assets = (data['assets'] as List?) ?? [];
      final installer = assets.cast<Map<String, dynamic>>().where(
        (a) => (a['name'] as String).toLowerCase().endsWith('.exe'),
      );

      if (installer.isEmpty) return null;

      final asset = installer.first;

      return UpdateInfo(
        version: latestVersion,
        currentVersion: currentVersion,
        downloadUrl: asset['browser_download_url'] as String,
        fileName: asset['name'] as String,
        changelog: (data['body'] as String?)?.trim() ?? 'Нет описания',
        size: asset['size'] as int? ?? 0,
        publishedAt: data['published_at'] as String?,
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Скачать обновление с прогрессом
  static Future<String> downloadUpdate({
    required UpdateInfo info,
    required void Function(double progress, int received, int total) onProgress,
    HttpClient? client,
  }) async {
    final httpClient = client ?? HttpClient();

    final savePath =
        '${Directory.systemTemp.path}\\SmartLauncher_Setup_${info.version}.exe';

    // Удаляем старый файл если есть
    final file = File(savePath);
    if (await file.exists()) await file.delete();

    try {
      final request = await httpClient.getUrl(Uri.parse(info.downloadUrl));
      request.headers.set('User-Agent', 'SmartLauncher-Updater');
      final response = await request.close();

      final totalBytes =
          response.contentLength > 0 ? response.contentLength : info.size;
      var receivedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Проверяем размер
      final actualSize = await file.length();
      if (info.size > 0 && (actualSize - info.size).abs() > 1024) {
        await file.delete();
        throw Exception('Размер файла не совпадает');
      }

      return savePath;
    } catch (e) {
      // Удаляем битый файл
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  /// Установить обновление (закрывает приложение!)
  static Future<void> installUpdate(String installerPath) async {
    final appExePath = Platform.resolvedExecutable;

    final batPath = '${Directory.systemTemp.path}\\sl_update.bat';
    final batContent = '''
@echo off
echo Waiting for SmartLauncher to close...
timeout /t 2 /nobreak >nul
taskkill /F /IM $exeName >nul 2>&1
timeout /t 2 /nobreak >nul
echo Starting installer...
"$installerPath" /VERYSILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS
echo Waiting for install to finish...
timeout /t 3 /nobreak >nul
echo Starting SmartLauncher...
start "" "$appExePath"
del "$installerPath" >nul 2>&1
del "%~f0"
''';

    await File(batPath).writeAsString(batContent);

    await Process.start(
      'cmd.exe',
      ['/c', batPath],
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }

  /// Сравнение версий: 1.1.0 > 1.0.0 → true
  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  /// Форматирование байт
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / 1073741824).toStringAsFixed(1)} ГБ';
  }
}