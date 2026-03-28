import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/home_screen.dart';
import 'services/tray_service.dart';
import 'theme/app_theme.dart';

// Уникальный порт для нашего лаунчера
const int _appPort = 53142; 

Future<void> _ensureSingleInstance() async {
  try {
    // Пытаемся занять порт. Если успешно — мы первая копия.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _appPort);
    server.listen((Socket client) {
      client.listen((data) {
        final msg = String.fromCharCodes(data);
        if (msg == 'wake_up') {
          // Пришёл сигнал от второй копии -> разворачиваем окно
          TrayService.show();
        }
      });
    });
  } catch (e) {
    // Ошибка bind() означает, что порт занят -> приложение уже работает.
    // Отправляем работающей копии сигнал и закрываемся.
    try {
      final client = await Socket.connect(InternetAddress.loopbackIPv4, _appPort);
      client.write('wake_up');
      await client.flush();
      await client.close();
    } catch (_) {}
    exit(0); // Тихо закрываем вторую копию
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. ПРОВЕРЯЕМ КОПИИ ДО ЗАПУСКА UI
  await _ensureSingleInstance();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await TrayService.init();

  runApp(const SmartLauncherApp());
}

class SmartLauncherApp extends StatelessWidget {
  const SmartLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartLauncher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}