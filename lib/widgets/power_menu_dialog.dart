import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';

enum PowerAction { shutdown, restart, sleep, hibernate, lock, cancel }

class PowerMenuResult {
  final PowerAction action;
  final int? minutes;

  const PowerMenuResult({required this.action, this.minutes});
}

class PowerMenuDialog extends StatefulWidget {
  const PowerMenuDialog({super.key});

  static Future<PowerMenuResult?> show(BuildContext context) {
    return showDialog<PowerMenuResult>(
      context: context,
      builder: (context) => const PowerMenuDialog(),
    );
  }

  @override
  State<PowerMenuDialog> createState() => _PowerMenuDialogState();
}

class _PowerMenuDialogState extends State<PowerMenuDialog>
    with SingleTickerProviderStateMixin {
  PowerAction? _selectedAction;
  final _minutesController = TextEditingController(text: '60');
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

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
    _minutesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _needsTimer =>
      _selectedAction == PowerAction.shutdown ||
      _selectedAction == PowerAction.restart;

  void _confirm() {
    if (_selectedAction == null) return;

    int? minutes;
    if (_needsTimer) {
      minutes = int.tryParse(_minutesController.text);
      if (minutes == null || minutes < 0) {
        minutes = 0;
      }
    }

    Navigator.pop(
      context,
      PowerMenuResult(action: _selectedAction!, minutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 620),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionGrid(),
                      if (_needsTimer) ...[
                        const SizedBox(height: 20),
                        _buildTimerInput(),
                      ],
                      const SizedBox(height: 24),
                      _buildButtons(),
                    ],
                  ),
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
            const Color(0xFFEF4444).withValues(alpha: 0.1),
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
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.power_settings_new,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Управление питанием',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Выберите действие',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.close_circle, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      _PowerOption(
        action: PowerAction.shutdown,
        icon: Icons.power_settings_new,
        label: 'Выключить',
        subtitle: 'Выключение по таймеру',
        color: const Color(0xFFEF4444),
      ),
      _PowerOption(
        action: PowerAction.restart,
        icon: Iconsax.refresh,
        label: 'Перезагрузка',
        subtitle: 'Перезагрузить ПК',
        color: const Color(0xFFF97316),
      ),
      _PowerOption(
        action: PowerAction.sleep,
        icon: Iconsax.moon,
        label: 'Сон',
        subtitle: 'Режим сна',
        color: const Color(0xFF8B5CF6),
      ),
      _PowerOption(
        action: PowerAction.hibernate,
        icon: Iconsax.cloud,
        label: 'Гибернация',
        subtitle: 'Глубокий сон',
        color: const Color(0xFF6366F1),
      ),
      _PowerOption(
        action: PowerAction.lock,
        icon: Iconsax.lock,
        label: 'Блокировка',
        subtitle: 'Заблокировать ПК',
        color: const Color(0xFF06B6D4),
      ),
      _PowerOption(
        action: PowerAction.cancel,
        icon: Iconsax.close_square,
        label: 'Отмена',
        subtitle: 'Отменить таймер',
        color: const Color(0xFF22C55E),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildActionTile(actions[index]);
      },
    );
  }

  Widget _buildActionTile(_PowerOption option) {
    final isSelected = _selectedAction == option.action;

    return GestureDetector(
      onTap: () => setState(() => _selectedAction = option.action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.15)
              : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? option.color.withValues(alpha: 0.5)
                : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withValues(alpha: 0.2)
                    : option.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                color: isSelected ? option.color : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.subtitle,
              style: TextStyle(
                color: isSelected
                    ? option.color.withValues(alpha: 0.8)
                    : AppTheme.textMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerInput() {
    final color = _selectedAction == PowerAction.shutdown
        ? const Color(0xFFEF4444)
        : const Color(0xFFF97316);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.clock, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                _selectedAction == PowerAction.shutdown
                    ? 'Через сколько минут выключить?'
                    : 'Через сколько минут перезагрузить?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimerButton(
                icon: Icons.remove,
                color: color,
                onPressed: () {
                  final current =
                      int.tryParse(_minutesController.text) ?? 0;
                  final newVal = (current - 5).clamp(0, 1440);
                  _minutesController.text = newVal.toString();
                  setState(() {});
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _minutesController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'мин',
                    suffixStyle: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: color.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTimerButton(
                icon: Icons.add,
                color: color,
                onPressed: () {
                  final current =
                      int.tryParse(_minutesController.text) ?? 0;
                  final newVal = (current + 5).clamp(0, 1440);
                  _minutesController.text = newVal.toString();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [15, 30, 60, 120].map((mins) {
              final isActive = _minutesController.text == mins.toString();
              return GestureDetector(
                onTap: () {
                  _minutesController.text = mins.toString();
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withValues(alpha: 0.2)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? color.withValues(alpha: 0.5)
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Text(
                    mins >= 60 ? '${mins ~/ 60}ч' : '${mins}м',
                    style: TextStyle(
                      color: isActive ? color : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppTheme.bgDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final actionColor = _selectedAction != null
        ? _getActionColor(_selectedAction!)
        : AppTheme.primaryColor;

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
            onPressed: _selectedAction != null ? _confirm : null,
            icon: Icon(
              _selectedAction != null
                  ? _getActionIcon(_selectedAction!)
                  : Iconsax.play,
              size: 18,
            ),
            label: Text(
              _selectedAction != null
                  ? _getActionButtonText(_selectedAction!)
                  : 'Выберите действие',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
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

  Color _getActionColor(PowerAction action) {
    return switch (action) {
      PowerAction.shutdown => const Color(0xFFEF4444),
      PowerAction.restart => const Color(0xFFF97316),
      PowerAction.sleep => const Color(0xFF8B5CF6),
      PowerAction.hibernate => const Color(0xFF6366F1),
      PowerAction.lock => const Color(0xFF06B6D4),
      PowerAction.cancel => const Color(0xFF22C55E),
    };
  }

  IconData _getActionIcon(PowerAction action) {
    return switch (action) {
      PowerAction.shutdown => Icons.power_settings_new,
      PowerAction.restart => Iconsax.refresh,
      PowerAction.sleep => Iconsax.moon,
      PowerAction.hibernate => Iconsax.cloud,
      PowerAction.lock => Iconsax.lock,
      PowerAction.cancel => Iconsax.close_square,
    };
  }

  String _getActionButtonText(PowerAction action) {
    return switch (action) {
      PowerAction.shutdown => 'Выключить',
      PowerAction.restart => 'Перезагрузить',
      PowerAction.sleep => 'Перейти в сон',
      PowerAction.hibernate => 'Гибернация',
      PowerAction.lock => 'Заблокировать',
      PowerAction.cancel => 'Отменить таймер',
    };
  }
}

class _PowerOption {
  final PowerAction action;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _PowerOption({
    required this.action,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}