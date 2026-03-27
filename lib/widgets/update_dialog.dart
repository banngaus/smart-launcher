import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

enum _UpdateState { checking, available, downloading, installing, upToDate, error }

class UpdateDialog extends StatefulWidget {
  final UpdateInfo? updateInfo;

  const UpdateDialog({super.key, this.updateInfo});

  /// Вызови это откуда угодно
  static Future<void> show(BuildContext context, {UpdateInfo? updateInfo}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _UpdateState _state = _UpdateState.checking;
  UpdateInfo? _info;
  String? _error;

  double _progress = 0;
  int _received = 0;
  int _total = 0;
  String? _downloadedPath;

  HttpClient? _httpClient;

  @override
  void initState() {
    super.initState();
    if (widget.updateInfo != null) {
      _info = widget.updateInfo;
      _state = _UpdateState.available;
    } else {
      _checkUpdate();
    }
  }

  @override
  void dispose() {
    _httpClient?.close(force: true);
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _state = _UpdateState.checking;
      _error = null;
    });

    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;

      if (info != null) {
        setState(() {
          _info = info;
          _state = _UpdateState.available;
        });
      } else {
        setState(() => _state = _UpdateState.upToDate);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _UpdateState.error;
          _error = 'Не удалось проверить обновления.\n'
              'Проверьте подключение к интернету.';
        });
      }
    }
  }

  Future<void> _startDownload() async {
    if (_info == null) return;

    _httpClient = HttpClient();

    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
      _received = 0;
      _total = _info!.size;
    });

    try {
      final path = await UpdateService.downloadUpdate(
        info: _info!,
        client: _httpClient,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _received = received;
              _total = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadedPath = path;
          _state = _UpdateState.installing;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _UpdateState.error;
          _error = 'Ошибка скачивания: $e';
        });
      }
    }
  }

  void _cancelDownload() {
    _httpClient?.close(force: true);
    _httpClient = null;
    if (mounted) {
      setState(() => _state = _UpdateState.available);
    }
  }

  Future<void> _install() async {
    if (_downloadedPath == null) return;
    await UpdateService.installUpdate(_downloadedPath!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _UpdateState.checking:
        return _buildChecking();
      case _UpdateState.available:
        return _buildAvailable();
      case _UpdateState.downloading:
        return _buildDownloading();
      case _UpdateState.installing:
        return _buildInstalling();
      case _UpdateState.upToDate:
        return _buildUpToDate();
      case _UpdateState.error:
        return _buildError();
    }
  }

  // ═══ Проверка ═══
  Widget _buildChecking() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: AppTheme.primaryColor),
      const SizedBox(height: 24),
      const Text(
        'Проверяем обновления...',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        'Текущая версия: ${UpdateService.currentVersion}',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
    ]);
  }

  // ═══ Есть обновление ═══
  Widget _buildAvailable() {
    final info = _info!;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Заголовок
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.arrow_up_1, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Доступно обновление!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text(
                  info.currentVersion,
                  style: TextStyle(
                    color: AppTheme.textMuted, fontSize: 14,
                    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Iconsax.arrow_right_3, size: 14, color: AppTheme.primaryColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.version,
                    style: TextStyle(
                      color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Размер + дата
      Row(children: [
        _infoBadge(Iconsax.document_download, UpdateService.formatBytes(info.size)),
        const SizedBox(width: 8),
        if (info.publishedAt != null)
          _infoBadge(Iconsax.calendar_1, _formatDate(info.publishedAt!)),
      ]),
      const SizedBox(height: 16),

      // Changelog
      Flexible(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Что нового:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  info.changelog,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 20),

      // Кнопки
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Позже'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Iconsax.arrow_down_2, size: 18),
            label: const Text('Скачать и установить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ═══ Скачивание ═══
  Widget _buildDownloading() {
    final percent = (_progress * 100).toStringAsFixed(1);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      const Icon(Iconsax.arrow_down_2, color: AppTheme.primaryColor, size: 40),
      const SizedBox(height: 20),
      const Text(
        'Скачивание обновления...',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 24),

      // Прогресс
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppTheme.bgDark,
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          minHeight: 12,
        ),
      ),
      const SizedBox(height: 12),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          '$percent%',
          style: TextStyle(
            color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
          ),
        ),
        Text(
          '${UpdateService.formatBytes(_received)} / ${UpdateService.formatBytes(_total)}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ]),
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _cancelDownload,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textMuted,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Отмена'),
        ),
      ),
    ]);
  }

  // ═══ Готово к установке ═══
  Widget _buildInstalling() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Iconsax.tick_circle, color: Color(0xFF22C55E), size: 40),
      ),
      const SizedBox(height: 20),
      const Text(
        'Обновление скачано!',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text(
        'Приложение закроется, установит обновление\nи запустится заново.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 24),

      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Не сейчас'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _install,
            icon: const Icon(Iconsax.arrow_up_1, size: 18),
            label: const Text('Установить сейчас'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ═══ Актуальная версия ═══
  Widget _buildUpToDate() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Iconsax.tick_circle, color: Color(0xFF22C55E), size: 40),
      ),
      const SizedBox(height: 20),
      const Text(
        'У вас актуальная версия!',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        'Версия ${UpdateService.currentVersion}',
        style: TextStyle(
          color: AppTheme.textMuted, fontSize: 14,
          fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.bgDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Закрыть'),
        ),
      ),
    ]);
  }

  // ═══ Ошибка ═══
  Widget _buildError() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Iconsax.warning_2, color: Color(0xFFEF4444), size: 40),
      ),
      const SizedBox(height: 20),
      const Text(
        'Ошибка',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Text(
        _error ?? 'Неизвестная ошибка',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
            child: const Text('Закрыть'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _checkUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Повторить'),
          ),
        ),
      ]),
    ]);
  }

  // ═══ Хелперы ═══
  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year}';
    } catch (_) {
      return '';
    }
  }
}