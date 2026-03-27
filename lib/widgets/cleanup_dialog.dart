import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';

class CleanupItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool needsAdmin;
  bool selected;

  CleanupItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.needsAdmin = false,
    this.selected = false,
  });
}

class CleanupDialog extends StatefulWidget {
  const CleanupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const CleanupDialog(),
    );
  }

  @override
  State<CleanupDialog> createState() => _CleanupDialogState();
}

class _CleanupDialogState extends State<CleanupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  bool _isRunning = false;
  bool _isDone = false;
  String _currentTask = '';
  double _progress = 0;
  final List<String> _log = [];
  double _totalFreed = 0;

  final List<CleanupItem> _items = [
    // ═══ Основные ═══
    CleanupItem(
      id: 'temp_user',
      name: 'Папка TEMP (пользователь)',
      description: 'Временные файлы текущего пользователя',
      icon: Iconsax.trash,
      color: const Color(0xFFEF4444),
      selected: true,
    ),
    CleanupItem(
      id: 'temp_system',
      name: 'Папка TEMP (система)',
      description: 'Системные временные файлы Windows',
      icon: Iconsax.monitor,
      color: const Color(0xFFF97316),
      selected: true,
    ),
    CleanupItem(
      id: 'recycle_bin',
      name: 'Корзина',
      description: 'Очистить корзину Windows',
      icon: Iconsax.trash,
      color: const Color(0xFF8B5CF6),
      selected: true,
    ),

    // ═══ Системные ═══
    CleanupItem(
      id: 'windows_update',
      name: 'Кэш обновлений Windows',
      description: 'Скачанные файлы Windows Update (может быть много ГБ)',
      icon: Iconsax.arrow_down_2,
      color: const Color(0xFF3B82F6),
      needsAdmin: true,
    ),
    CleanupItem(
      id: 'prefetch',
      name: 'Prefetch',
      description: 'Кэш предзагрузки Windows',
      icon: Iconsax.cpu,
      color: const Color(0xFF06B6D4),
    ),
    CleanupItem(
      id: 'restore_points',
      name: 'Точки восстановления',
      description: 'Удалить все точки кроме последней',
      icon: Iconsax.clock,
      color: const Color(0xFFEC4899),
      needsAdmin: true,
    ),
    CleanupItem(
      id: 'font_cache',
      name: 'Кэш шрифтов',
      description: 'Системный кэш шрифтов Windows',
      icon: Iconsax.text,
      color: const Color(0xFF14B8A6),
      needsAdmin: true,
    ),
    CleanupItem(
      id: 'icon_cache',
      name: 'Кэш иконок и миниатюр',
      description: 'Превью изображений и иконки в проводнике',
      icon: Iconsax.image,
      color: const Color(0xFF22C55E),
    ),
    CleanupItem(
      id: 'logs',
      name: 'Логи Windows',
      description: 'Системные журналы и отчёты об ошибках',
      icon: Iconsax.document_text,
      color: const Color(0xFFF59E0B),
    ),

    // ═══ Браузеры ═══
    CleanupItem(
      id: 'browser_cache',
      name: 'Кэш браузеров',
      description: 'Chrome, Edge, Firefox — кэш и временные файлы',
      icon: Iconsax.global,
      color: const Color(0xFF6366F1),
    ),

    // ═══ Прочее ═══
    CleanupItem(
      id: 'recent',
      name: 'Недавние файлы',
      description: 'Список последних открытых файлов',
      icon: Iconsax.clock,
      color: const Color(0xFF0EA5E9),
    ),
    CleanupItem(
      id: 'dns_cache',
      name: 'DNS кэш',
      description: 'Кэш DNS-запросов',
      icon: Iconsax.wifi,
      color: const Color(0xFF7C3AED),
    ),
    CleanupItem(
      id: 'crash_dumps',
      name: 'Дампы ошибок',
      description: 'Файлы аварийных дампов Windows',
      icon: Iconsax.warning_2,
      color: const Color(0xFFDC2626),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _selectedCount => _items.where((i) => i.selected).length;
  bool get _hasAdminTasks =>
      _items.where((i) => i.selected && i.needsAdmin).isNotEmpty;

  void _toggleAll(bool value) {
    setState(() {
      for (final item in _items) {
        item.selected = value;
      }
    });
  }

  Future<void> _runCleanup() async {
    final selected = _items.where((i) => i.selected).toList();
    if (selected.isEmpty) return;

    setState(() {
      _isRunning = true;
      _log.clear();
      _totalFreed = 0;
      _progress = 0;
    });

    for (int i = 0; i < selected.length; i++) {
      final item = selected[i];
      setState(() {
        _currentTask = item.name;
        _progress = i / selected.length;
      });

      try {
        final freed = await _executeCleanup(item.id);
        final freedMB = freed / 1024 / 1024;
        _totalFreed += freedMB;

        setState(() {
          if (freedMB > 0.1) {
            _log.add('[OK] ${item.name}: ${freedMB.toStringAsFixed(1)} MB');
          } else {
            _log.add('[--] ${item.name}: уже чисто');
          }
        });
      } catch (e) {
        setState(() {
          _log.add('[ERR] ${item.name}: $e');
        });
      }
    }

    setState(() {
      _isRunning = false;
      _isDone = true;
      _progress = 1.0;
      _currentTask = '';
    });
  }

  Future<int> _executeCleanup(String id) async {
    switch (id) {
      case 'temp_user':
        return _cleanDirectory(Platform.environment['TEMP'] ?? '');

      case 'temp_system':
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        return _cleanDirectory('$winDir\\Temp');

      case 'recycle_bin':
        await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            'Clear-RecycleBin -Force -ErrorAction SilentlyContinue',
          ],
          runInShell: true,
        );
        return 0;

      case 'windows_update':
        // Останавливаем службу, чистим, запускаем
        await _runPowerShell('''
          Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
          Stop-Service bits -Force -ErrorAction SilentlyContinue
        ''');
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        final freed =
            await _cleanDirectory('$winDir\\SoftwareDistribution\\Download');
        await _runPowerShell('''
          Start-Service wuauserv -ErrorAction SilentlyContinue
          Start-Service bits -ErrorAction SilentlyContinue
        ''');
        return freed;

      case 'prefetch':
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        return _cleanDirectory('$winDir\\Prefetch');

      case 'restore_points':
        await _runPowerShell(
          'vssadmin delete shadows /for=C: /oldest /quiet',
        );
        return 0;

      case 'font_cache':
        await _runPowerShell('''
          Stop-Service FontCache -Force -ErrorAction SilentlyContinue
          Stop-Service FontCache3.0.0.0 -Force -ErrorAction SilentlyContinue
        ''');
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        final freed = await _cleanDirectory(
          '$winDir\\ServiceProfiles\\LocalService\\AppData\\Local\\FontCache',
        );
        await _runPowerShell('''
          Start-Service FontCache -ErrorAction SilentlyContinue
        ''');
        return freed;

      case 'icon_cache':
        final localAppData =
            Platform.environment['LOCALAPPDATA'] ?? '';
        int freed = 0;

        // Кэш миниатюр
        freed += await _cleanDirectory(
          '$localAppData\\Microsoft\\Windows\\Explorer',
          pattern: 'thumbcache_*.db',
        );

        // Кэш иконок
        freed += await _cleanDirectory(
          '$localAppData\\Microsoft\\Windows\\Explorer',
          pattern: 'iconcache_*.db',
        );

        // Перестроить кэш иконок
        await _runPowerShell(
          'ie4uinit.exe -show',
        );
        return freed;

      case 'logs':
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        int freed = 0;
        freed += await _cleanDirectory('$winDir\\Logs');
        freed += await _cleanDirectory('$winDir\\Panther');

        // Очистка журналов событий
        await _runPowerShell(
          r"wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }",
        );
        return freed;

      case 'browser_cache':
        final localAppData =
            Platform.environment['LOCALAPPDATA'] ?? '';
        final appData = Platform.environment['APPDATA'] ?? '';
        int freed = 0;

        // Chrome
        freed += await _cleanDirectory(
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Cache',
        );
        freed += await _cleanDirectory(
          '$localAppData\\Google\\Chrome\\User Data\\Default\\Code Cache',
        );

        // Edge
        freed += await _cleanDirectory(
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\Cache',
        );
        freed += await _cleanDirectory(
          '$localAppData\\Microsoft\\Edge\\User Data\\Default\\Code Cache',
        );

        // Firefox
        try {
          final profilesDir =
              Directory('$appData\\Mozilla\\Firefox\\Profiles');
          if (await profilesDir.exists()) {
            await for (final profile in profilesDir.list()) {
              if (profile is Directory) {
                freed += await _cleanDirectory(
                    '${profile.path}\\cache2');
              }
            }
          }
        } catch (_) {}

        return freed;

      case 'recent':
        final appData = Platform.environment['APPDATA'] ?? '';
        return _cleanDirectory(
          '$appData\\Microsoft\\Windows\\Recent',
        );

      case 'dns_cache':
        await Process.run('ipconfig', ['/flushdns'], runInShell: true);
        return 0;

      case 'crash_dumps':
        final localAppData =
            Platform.environment['LOCALAPPDATA'] ?? '';
        final winDir =
            Platform.environment['SYSTEMROOT'] ?? r'C:\Windows';
        int freed = 0;
        freed += await _cleanDirectory('$localAppData\\CrashDumps');
        freed += await _cleanDirectory('$winDir\\Minidump');
        freed += await _cleanDirectory('$winDir\\LiveKernelReports');

        // Удаляем файлы MEMORY.DMP
        try {
          final dmp = File('$winDir\\MEMORY.DMP');
          if (await dmp.exists()) {
            final size = await dmp.length();
            await dmp.delete();
            freed += size;
          }
        } catch (_) {}
        return freed;

      default:
        return 0;
    }
  }

  Future<void> _runPowerShell(String command) async {
    await Process.run(
      'powershell',
      ['-NoProfile', '-Command', command],
      runInShell: true,
    );
  }

  Future<int> _cleanDirectory(String path, {String? pattern}) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int freed = 0;
    try {
      await for (final entity in dir.list()) {
        try {
          if (pattern != null) {
            final name = entity.uri.pathSegments.last;
            if (!RegExp(
              pattern.replaceAll('.', r'\.').replaceAll('*', '.*'),
            ).hasMatch(name)) {
              continue;
            }
          }

          final stat = await entity.stat();
          final size = stat.size;

          if (entity is File) {
            await entity.delete();
            freed += size;
          } else if (entity is Directory) {
            final dirSize = await _getDirSize(entity);
            await entity.delete(recursive: true);
            freed += dirSize;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return freed;
  }

  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 720),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isDone ? _buildResults() : _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Iconsax.broom,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Очистка системы',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRunning
                      ? 'Выполняется очистка...'
                      : _isDone
                          ? 'Очистка завершена!'
                          : 'Выберите что очистить',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!_isRunning)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.close_circle,
                  color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isRunning)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  'Выбрано: $_selectedCount из ${_items.length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (_hasAdminTasks) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.shield,
                            size: 12, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          'Нужен админ',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => _toggleAll(true),
                  child:
                      const Text('Выбрать всё', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _toggleAll(false),
                  child:
                      const Text('Снять всё', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        ...List.generate(
            _items.length, (i) => _buildCleanupTile(_items[i])),

        if (_isRunning) ...[
          const SizedBox(height: 20),
          Text(
            _currentTask,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppTheme.bgDark,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF22C55E)),
              minHeight: 8,
            ),
          ),
        ],

        if (!_isRunning) ...[
          const SizedBox(height: 20),
          _buildButtons(),
        ],
      ],
    );
  }

  Widget _buildCleanupTile(CleanupItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _isRunning
            ? null
            : () => setState(() => item.selected = !item.selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.selected
                ? item.color.withValues(alpha: 0.08)
                : AppTheme.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.selected
                  ? item.color.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.selected
                      ? item.color.withValues(alpha: 0.15)
                      : item.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color:
                      item.selected ? item.color : AppTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: item.selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: item.selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (item.needsAdmin) ...[
                          const SizedBox(width: 6),
                          const Icon(Iconsax.shield,
                              size: 12, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.selected
                      ? item.color
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color:
                        item.selected ? item.color : AppTheme.textMuted,
                    width: 2,
                  ),
                ),
                child: item.selected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.tick_circle,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Очистка завершена!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalFreed >= 1024
                          ? 'Освобождено: ${(_totalFreed / 1024).toStringAsFixed(2)} GB'
                          : 'Освобождено: ${_totalFreed.toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Результаты:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._log.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: line.startsWith('[OK]')
                            ? const Color(0xFF22C55E)
                            : line.startsWith('[ERR]')
                                ? const Color(0xFFEF4444)
                                : AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Закрыть'),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: const Text(
              'Отмена',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _selectedCount > 0 ? _runCleanup : null,
            icon: const Icon(Iconsax.broom, size: 18),
            label: Text('Очистить ($_selectedCount)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.bgDark,
              disabledForegroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}