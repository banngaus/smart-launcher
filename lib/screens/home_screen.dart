import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:window_manager/window_manager.dart';

import '../models/command_item.dart';
import '../services/config_service.dart';
import '../services/dialog_handler.dart';
import '../services/script_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/log_modal.dart';
import '../widgets/add_script_dialog.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/cleanup_dialog.dart';
import 'converter_screen.dart';
import 'apps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _currentTab = 0;
  List<CommandItem> _commands = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  String _searchQuery = '';
  final ScriptRunner _scriptRunner = ScriptRunner();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadCommands();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _scriptRunner.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  Future<void> _loadCommands() async {
    setState(() => _isLoading = true);
    final commands = await ConfigService.loadCommands();
    if (mounted) {
      setState(() {
        _commands = commands;
        _isLoading = false;
      });
    }
  }

  List<CommandItem> get _filteredCommands {
    return _commands.where((cmd) {
      final matchesCategory =
          _selectedCategory == 'all' || cmd.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          cmd.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cmd.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _handleCommandTap(CommandItem command) async {
    final dialogResult =
        await DialogHandler.handlePreRunDialog(context, command);
    if (!dialogResult.proceed || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogModal(
        command: command,
        scriptRunner: _scriptRunner,
        arguments: dialogResult.arguments,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScriptDialog(
        onSave: (command) async {
          await ConfigService.addCommand(command);
          _loadCommands();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgDark,
      endDrawer: SettingsDrawer(onReset: _loadCommands),
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: switch (_currentTab) {
              0 => Row(
                  children: [
                    _buildScriptsSidebar(),
                    Expanded(child: _buildScriptsContent()),
                  ],
                ),
              1 => const ConverterScreen(),
              2 => const AppsScreen(),
              _ => const SizedBox(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.command_square,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'SmartLauncher',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 32),
            _buildTab(0, 'Скрипты', Iconsax.command_square),
            _buildTab(1, 'Конвертер', Iconsax.convert),
            _buildTab(2, 'Приложения', Iconsax.element_plus),
            const Spacer(),
            _buildTitleBarButton(
              icon: Iconsax.setting_2,
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            const SizedBox(width: 4),
            _buildWindowButton(
                icon: Icons.remove,
                onTap: () => windowManager.minimize()),
            _buildWindowButton(
              icon: Icons.crop_square,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _buildWindowButton(
              icon: Icons.close,
              onTap: () => windowManager.hide(),
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isClose
            ? Colors.red.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
        child: SizedBox(
          width: 46,
          height: 50,
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildScriptsSidebar() {
    const categories = [
      ('all', 'Все', Iconsax.category),
      ('power', 'Питание', Icons.power_settings_new),
      ('system', 'Система', Iconsax.monitor),
      ('network', 'Сеть', Iconsax.wifi),
      ('files', 'Файлы', Iconsax.folder),
      ('media', 'Медиа', Iconsax.image),
      ('custom', 'Мои скрипты', Iconsax.code),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(right: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value),
                style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Поиск...',
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
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
          ),
          const SizedBox(height: 8),
          ...categories.map((cat) => _buildCategoryItem(
                id: cat.$1,
                label: cat.$2,
                icon: cat.$3,
              )),
          const Spacer(),

          // ═══ Кнопка очистки системы ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => CleanupDialog.show(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF22C55E).withValues(alpha: 0.15),
                        const Color(0xFF16A34A).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          const Color(0xFF22C55E).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.broom,
                          color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Очистка системы',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildSidebarButton(
              icon: Iconsax.folder_open,
              label: 'Папка скриптов',
              onTap: () => ConfigService.openScriptsFolder(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == id;
    final count = id == 'all'
        ? _commands.length
        : _commands.where((c) => c.category == id).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptsContent() {
    return Container(
      color: AppTheme.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredCommands.length} команд доступно',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Iconsax.add, size: 20),
                  label: const Text('Добавить скрипт'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadCommands,
                  icon: const Icon(Iconsax.refresh),
                  tooltip: 'Обновить',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.bgCard,
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : _filteredCommands.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredCommands.length,
      itemBuilder: (context, index) {
        final command = _filteredCommands[index];
        return ActionCard(
          command: command,
          onTap: () => _handleCommandTap(command),
          onDelete: () async {
            await ConfigService.removeCommand(command.id);
            _loadCommands();
          },
        )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            )
            .slideY(
              begin: 0.1,
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.document, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Ничего не найдено'
                : 'Скрипты не найдены',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Попробуйте другой запрос'
                : 'Добавьте свой первый скрипт',
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Iconsax.add, size: 20),
              label: const Text('Добавить скрипт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryTitle() {
    const titles = {
      'all': 'Все скрипты',
      'power': 'Питание',
      'system': 'Система',
      'network': 'Сеть',
      'files': 'Файлы',
      'media': 'Медиа',
      'custom': 'Мои скрипты',
    };
    return titles[_selectedCategory] ?? 'Скрипты';
  }
}