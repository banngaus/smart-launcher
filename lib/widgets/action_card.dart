import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/command_item.dart';
import '../theme/app_theme.dart';

class ActionCard extends StatefulWidget {
  final CommandItem command;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ActionCard({
    super.key,
    required this.command,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.command.colorValue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isHovered
                    ? color.withValues(alpha: 0.15)
                    : AppTheme.bgCard,
                _isHovered
                    ? color.withValues(alpha: 0.05)
                    : AppTheme.bgCard.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? color.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Glow effect on hover
              if (_isHovered)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: icon + badges + delete
                    Row(
                      children: [
                        _buildIcon(color),
                        const Spacer(),
                        ..._buildBadges(),
                        if (_isHovered && widget.onDelete != null)
                          IconButton(
                            onPressed: _showDeleteConfirmation,
                            icon: Icon(Iconsax.trash,
                                color: AppTheme.errorColor, size: 18),
                            tooltip: 'Удалить',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Name
                    Text(
                      widget.command.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      widget.command.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Run button (visible on hover)
                    _buildRunButton(color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(
        widget.command.iconData,
        color: color,
        size: 24,
      ),
    );
  }

  List<Widget> _buildBadges() {
    final badges = <Widget>[];

    if (widget.command.hasParameters) {
      badges.add(_buildBadge(
        icon: Iconsax.setting_4,
        label: 'Настройки',
        color: AppTheme.primaryColor,
      ));
    }

    if (widget.command.requiresAdmin) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_buildBadge(
        icon: Iconsax.shield_tick,
        label: 'Admin',
        color: AppTheme.warningColor,
        hasBorder: true,
      ));
    }

    return badges;
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    bool hasBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: hasBorder
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(Color color) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isHovered ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.command.hasParameters ? Iconsax.setting_4 : Iconsax.play,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              widget.command.hasParameters ? 'Настроить' : 'Запустить',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderLight),
        ),
        title: const Text('Удалить скрипт?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Вы уверены, что хотите удалить "${widget.command.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}