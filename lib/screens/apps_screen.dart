import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../services/app_installer_service.dart';
import '../theme/app_theme.dart';

class AppInfo {
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final String url;
  final String? registryName;

  const AppInfo({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.url,
    this.registryName,
  });
}

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final _service = AppInstallerService();

  static const List<AppInfo> apps = [
    // ═══ Утилиты ═══
    AppInfo(
      name: '7-Zip',
      description: 'Бесплатный архиватор с высокой степенью сжатия',
      category: 'utilities',
      icon: Iconsax.archive_1,
      color: Color(0xFF22C55E),
      url: 'https://www.7-zip.org/a/7z2408-x64.exe',
      registryName: '7-Zip',
    ),
    AppInfo(
      name: 'Everything',
      description: 'Мгновенный поиск файлов на компьютере',
      category: 'utilities',
      icon: Iconsax.search_normal,
      color: Color(0xFFF97316),
      url: 'https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe',
      registryName: 'Everything',
    ),
    AppInfo(
      name: 'Notepad++',
      description: 'Продвинутый текстовый редактор',
      category: 'utilities',
      icon: Iconsax.document_code,
      color: Color(0xFF22D3EE),
      url: 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.8/npp.8.7.8.Installer.x64.exe',
      registryName: 'Notepad++',
    ),

    // ═══ Медиа ═══
    AppInfo(
      name: 'VLC Media Player',
      description: 'Универсальный медиаплеер для любых форматов',
      category: 'media',
      icon: Iconsax.video_play,
      color: Color(0xFFF59E0B),
      url: 'https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe',
      registryName: 'VLC media player',
    ),
    AppInfo(
      name: 'K-Lite Codec Pack',
      description: 'Набор кодеков для воспроизведения любых медиа',
      category: 'media',
      icon: Iconsax.video,
      color: Color(0xFF8B5CF6),
      url: 'https://files2.codecguide.com/K-Lite_Codec_Pack_1895_Full.exe',
      registryName: 'K-Lite Codec Pack',
    ),

    // ═══ Интернет ═══
    AppInfo(
      name: 'Google Chrome',
      description: 'Быстрый и популярный веб-браузер',
      category: 'internet',
      icon: Iconsax.global,
      color: Color(0xFF3B82F6),
      url: 'https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B00000000-0000-0000-0000-000000000000%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/chrome/install/ChromeStandaloneSetup64.exe',
      registryName: 'Google Chrome',
    ),
    AppInfo(
      name: 'qBittorrent',
      description: 'Бесплатный торрент-клиент без рекламы',
      category: 'internet',
      icon: Iconsax.arrow_down_2,
      color: Color(0xFF2563EB),
      url: 'https://sourceforge.net/projects/qbittorrent/files/latest/download',
      registryName: 'qBittorrent',
    ),

    // ═══ Разработка ═══
    AppInfo(
      name: 'Git',
      description: 'Система контроля версий',
      category: 'dev',
      icon: Iconsax.code,
      color: Color(0xFFEF4444),
      url: 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe',
      registryName: 'Git',
    ),
    AppInfo(
      name: 'VS Code',
      description: 'Легковесный редактор кода от Microsoft',
      category: 'dev',
      icon: Iconsax.code_1,
      color: Color(0xFF0EA5E9),
      url: 'https://update.code.visualstudio.com/latest/win32-x64/stable',
      registryName: 'Microsoft Visual Studio Code',
    ),

    // ═══ Компоненты ═══
    AppInfo(
      name: 'Visual C++ All-in-One',
      description: 'Все версии Visual C++ (2005-2022) в одном пакете',
      category: 'system',
      icon: Iconsax.cpu,
      color: Color(0xFF7C3AED),
      url: 'https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe',
      registryName: 'Visual C++',
    ),
    AppInfo(
      name: 'DirectX End-User Runtime',
      description: 'Компоненты DirectX для игр и приложений',
      category: 'system',
      icon: Iconsax.game,
      color: Color(0xFF059669),
      url: 'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe',
      registryName: 'DirectX',
    ),
    AppInfo(
      name: '.NET Desktop Runtime 8',
      description: 'Среда выполнения .NET для приложений',
      category: 'system',
      icon: Iconsax.monitor,
      color: Color(0xFF512BD4),
      url: 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.16/windowsdesktop-runtime-8.0.16-win-x64.exe',
      registryName: '.NET',
    ),

    // ═══ Безопасность ═══
    AppInfo(
      name: 'Malwarebytes',
      description: 'Антивирусный сканер для удаления вредоносного ПО',
      category: 'security',
      icon: Iconsax.shield_tick,
      color: Color(0xFF0891B2),
      url: 'https://downloads.malwarebytes.com/file/mb-windows',
      registryName: 'Malwarebytes',
    ),
  ];

  static const _categories = [
    ('all', 'Все', Iconsax.category),
    ('utilities', 'Утилиты', Iconsax.setting_2),
    ('media', 'Медиа', Iconsax.video_play),
    ('internet', 'Интернет', Iconsax.global),
    ('dev', 'Разработка', Iconsax.code),
    ('system', 'Компоненты', Iconsax.cpu),
    ('security', 'Безопасность', Iconsax.shield_tick),
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    if (!_service.detectedApps) {
      _service.detectInstalledApps(
        apps.map((a) => (a.name, a.registryName)).toList(),
      );
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<AppInfo> get _filteredApps {
    var list = _selectedCategory == 'all'
        ? apps
        : apps.where((a) => a.category == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _handleInstall(AppInfo app) {
    _service.downloadAndOpen(name: app.name, url: app.url);

    final state = _service.getState(app.name);
    if (state?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${state!.error}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark,
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'КАТЕГОРИИ',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._categories.map((cat) {
            final isSel = _selectedCategory == cat.$1;
            final count = cat.$1 == 'all'
                ? apps.length
                : apps.where((a) => a.category == cat.$1).length;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedCategory = cat.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? AppTheme.primaryColor
                                .withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat.$3,
                            size: 18,
                            color: isSel
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.$2,
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.primaryColor
                                    .withValues(alpha: 0.2)
                                : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSel
                                  ? AppTheme.primaryColor
                                  : AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),

          // Обновить статус
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _service.detectInstalledApps(
                    apps.map((a) => (a.name, a.registryName)).toList(),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.refresh,
                          color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Text('Обновить статус',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Шапка
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Приложения',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredApps.length} приложений • '
                      '${_service.installed.length} установлено',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Поиск
              SizedBox(
                width: 260,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Поиск приложений...',
                      hintStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      prefixIcon: Icon(Iconsax.search_normal,
                          color: AppTheme.textMuted, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: Icon(Iconsax.close_circle,
                                  color: AppTheme.textMuted, size: 16),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Активные загрузки (показываются всегда сверху)
        if (_service.states.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _service.states.entries.map((e) {
                final s = e.value;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.error != null
                        ? AppTheme.errorColor.withValues(alpha: 0.1)
                        : s.isDone
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: s.error != null
                          ? AppTheme.errorColor.withValues(alpha: 0.3)
                          : s.isDone
                              ? AppTheme.successColor
                                  .withValues(alpha: 0.3)
                              : AppTheme.primaryColor
                                  .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.isDownloading)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: s.progress > 0 ? s.progress : null,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      else if (s.isDone)
                        const Icon(Iconsax.tick_circle,
                            size: 14, color: AppTheme.successColor)
                      else if (s.error != null)
                        const Icon(Iconsax.warning_2,
                            size: 14, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        '${s.appName}: ${s.status}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Сетка
        Expanded(
          child: _filteredApps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.search_normal,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      const Text('Ничего не найдено',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    return _buildAppCard(_filteredApps[index])
                        .animate()
                        .fadeIn(
                            duration: const Duration(milliseconds: 300),
                            delay: Duration(milliseconds: 50 * index))
                        .slideY(
                            begin: 0.1,
                            duration: const Duration(milliseconds: 300),
                            delay: Duration(milliseconds: 50 * index));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppCard(AppInfo app) {
    final state = _service.getState(app.name);
    final isDownloading = state?.isDownloading ?? false;
    final isInstalled = _service.isInstalled(app.name);
    final progress = state?.progress;
    final status = state?.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInstalled
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : isDownloading
                  ? app.color.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(app.icon, color: app.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(app.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              if (isInstalled && !isDownloading)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Color(0xFF22C55E), shape: BoxShape.circle),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 14),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(app.description,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const Spacer(),

          // Прогресс
          if (isDownloading && progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: AppTheme.bgDark,
                valueColor: AlwaysStoppedAnimation(app.color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(status ?? '',
                style: TextStyle(color: app.color, fontSize: 11)),
            const SizedBox(height: 6),
          ],

          // Кнопка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : () => _handleInstall(app),
              icon: isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: app.color))
                  : Icon(
                      isInstalled
                          ? Iconsax.tick_circle
                          : Iconsax.arrow_down_2,
                      size: 16),
              label: Text(
                isDownloading
                    ? 'Загрузка...'
                    : isInstalled
                        ? 'Переустановить'
                        : 'Скачать и установить',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isInstalled ? AppTheme.successColor : app.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.bgDark,
                disabledForegroundColor: app.color.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}