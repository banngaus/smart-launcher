import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../services/config_service.dart';
import '../services/script_runner.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/update_dialog.dart';

class SettingsDrawer extends StatefulWidget {
  final VoidCallback? onReset;

  const SettingsDrawer({super.key, this.onReset});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String? _pythonVersion;
  String? _ffmpegVersion;
  bool _isCheckingTools = true;
  bool _isMigrating = false;
  double? _migrationProgress;

  @override
  void initState() {
    super.initState();
    _checkTools();
  }

  Future<void> _checkTools() async {
    final pyVersion = await ScriptRunner.getPythonVersion();
    final ffVersion = await ScriptRunner.getFFmpegVersion();

    if (mounted) {
      setState(() {
        _pythonVersion = pyVersion;
        _ffmpegVersion = ffVersion;
        _isCheckingTools = false;
      });
    }
  }

  Future<void> _migrateLegacyScripts() async {
    setState(() {
      _isMigrating = true;
      _migrationProgress = 0.0;
    });

    try {
      await ConfigService.restoreAllBuiltInScripts();
      await ConfigService.resetToDefaults();

      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _migrationProgress = i / 100;
          });
        }
      }

      widget.onReset?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Скрипты и настройки обновлены!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка миграции: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
          _migrationProgress = null;
        });
      }
    }
  }

  Future<void> _openScriptsFolder() async {
    await ConfigService.openScriptsFolder();
  }

  Future<void> _openAppFolder() async {
    await ConfigService.openAppFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgSurface,
      width: 340,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.setting_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Настройки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppTheme.borderSubtle),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Tools
                    _buildSection(
                      title: 'ИНСТРУМЕНТЫ СИСТЕМЫ',
                      children: [
                        _buildStatusTile(
                          icon: Iconsax.code,
                          title: 'Python',
                          subtitle: _isCheckingTools
                              ? 'Проверка...'
                              : _pythonVersion ?? 'Не установлен',
                          isOk: _pythonVersion != null,
                          isLoading: _isCheckingTools,
                        ),
                        _buildStatusTile(
                          icon: Iconsax.video,
                          title: 'FFmpeg',
                          subtitle: _isCheckingTools
                              ? 'Проверка...'
                              : _ffmpegVersion ?? 'Не установлен',
                          isOk: _ffmpegVersion != null,
                          isLoading: _isCheckingTools,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // App Settings
                    _buildSection(
                      title: 'НАСТРОЙКИ ПРИЛОЖЕНИЯ',
                      children: [
                        _buildSettingsTile(
                          icon: Iconsax.folder_open,
                          title: 'Папка скриптов',
                          subtitle: 'Открыть папку со скриптами',
                          onTap: _openScriptsFolder,
                        ),
                        _buildSettingsTile(
                          icon: Iconsax.folder_2,
                          title: 'Папка приложения',
                          subtitle: 'Открыть AppData/SmartLauncher',
                          onTap: _openAppFolder,
                        ),
                        _buildSettingsTile(
                          icon: Iconsax.refresh,
                          title: 'Восстановить скрипты',
                          subtitle: 'Восстановить все встроенные скрипты',
                          onTap: _showRestoreScriptsDialog,
                        ),
                        _buildSettingsTile(
                          icon: Iconsax.trash,
                          title: 'Сбросить настройки',
                          subtitle: 'Вернуть к значениям по умолчанию',
                          onTap: _showResetConfirmation,
                          isDestructive: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Обновления
                    _buildSection(
                      title: 'ОБНОВЛЕНИЯ',
                      children: [
                        _buildSettingsTile(
                          icon: Iconsax.arrow_up_1,
                          title: 'Проверить обновления',
                          subtitle: 'Текущая версия: ${UpdateService.currentVersion}',
                          onTap: () => UpdateDialog.show(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Migration progress
            if (_isMigrating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: _migrationProgress,
                  backgroundColor: AppTheme.bgCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.heart,
                        color: AppTheme.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SmartLauncher v${UpdateService.currentVersion}',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isOk,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOk
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isOk ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          else
            Icon(
              isOk ? Iconsax.tick_circle : Iconsax.close_circle,
              color: isOk ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isMigrating ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppTheme.errorColor.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive
                            ? AppTheme.errorColor
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestoreScriptsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderLight),
        ),
        title: const Text(
          'Восстановить встроенные скрипты?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все встроенные скрипты будут перезаписаны оригинальными версиями.\n\n'
          'Пользовательские скрипты в папке scripts не будут затронуты.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ConfigService.restoreAllBuiltInScripts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Встроенные скрипты восстановлены!'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderLight),
        ),
        title: const Text(
          'Сбросить настройки?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все команды будут сброшены к значениям по умолчанию.\n\n'
          'Пользовательские скрипты в папке scripts останутся, '
          'но их записи в конфиге будут удалены.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _migrateLegacyScripts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}