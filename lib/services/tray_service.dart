import 'dart:developer' as dev;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class TrayService {
  static SystemTray? _tray;
  static bool _initialized = false;

  static Future<void> init() async {
    try {
      _tray = SystemTray();

      await _tray!.initSystemTray(
        title: 'SmartLauncher',
        iconPath: 'assets/icon/app_icon.ico',
        toolTip: 'SmartLauncher — Системные утилиты',
      );

      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Показать SmartLauncher',
          onClicked: (_) => show(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Выход',
          onClicked: (_) => quit(),
        ),
      ]);

      await _tray!.setContextMenu(menu);

      _tray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick ||
            eventName == kSystemTrayEventDoubleClick) {
          show();
        } else if (eventName == kSystemTrayEventRightClick) {
          _tray!.popUpContextMenu();
        }
      });

      _initialized = true;
      dev.log('System tray initialized', name: 'TrayService');
    } catch (e) {
      dev.log('Failed to init system tray: $e', name: 'TrayService');
      _initialized = false;
    }
  }

  static Future<void> show() async {
    // Проверяем, свёрнуто ли окно в таскбар (свёрнуто минусом)
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    
    // Вытаскиваем из трея и даем фокус
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> hide() async {
    await windowManager.hide();
  }

  static Future<void> quit() async {
    if (_initialized && _tray != null) {
      await _tray!.destroy();
    }
    await windowManager.destroy();
  }

  static bool get isInitialized => _initialized;
}