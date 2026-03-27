import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../models/command_item.dart';
import '../services/script_runner.dart';
import '../theme/app_theme.dart';

class LogModal extends StatefulWidget {
  final CommandItem command;
  final ScriptRunner scriptRunner;
  final Map<String, String>? arguments;

  const LogModal({
    super.key,
    required this.command,
    required this.scriptRunner,
    this.arguments,
  });

  @override
  State<LogModal> createState() => _LogModalState();
}

class _LogModalState extends State<LogModal> {
  final ScrollController _scrollController = ScrollController();
  final List<ScriptOutput> _outputs = [];
  StreamSubscription? _outputSubscription;
  StreamSubscription? _statusSubscription;
  ScriptStatus _status = ScriptStatus.idle;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _runScript();
  }

  void _setupListeners(ScriptRunSession session) {
    _outputSubscription?.cancel();
    _statusSubscription?.cancel();

    _outputSubscription = session.outputStream.listen((output) {
      if (mounted) {
        setState(() => _outputs.add(output));
        if (_autoScroll) _scrollToBottom();
      }
    });

    _statusSubscription = session.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runScript() async {
    setState(() {
      _outputs.clear();
      _status = ScriptStatus.running;
    });
    final session = widget.scriptRunner.createSession();
    _setupListeners(session);
    await widget.scriptRunner.runScript(widget.command, arguments: widget.arguments);
  }

  void _copyLogs() {
    final text = _outputs.map((o) {
      final time =
          '${o.timestamp.hour.toString().padLeft(2, '0')}:'
          '${o.timestamp.minute.toString().padLeft(2, '0')}:'
          '${o.timestamp.second.toString().padLeft(2, '0')}';
      return '$time ${o.isError ? '[ERR] ' : ''}${o.text}';
    }).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Логи скопированы'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ищет путь к выходному файлу в логах
  String? _findOutputPath() {
    for (final output in _outputs.reversed) {
      final text = output.text;
      // Ищем паттерны вроде "Файл: ...", "Сохранено: ...", "Результаты: ..."
      for (final prefix in ['Файл:', 'Результаты:', 'Сохранено:']) {
        if (text.contains(prefix)) {
          final path = text.split(prefix).last.trim();
          if (path.isNotEmpty) return path;
        }
      }
      // Ищем путь с буквой диска
      final match = RegExp(r'[A-Z]:\\[^\s"]+').firstMatch(text);
      if (match != null) return match.group(0);
    }
    // Проверяем аргументы
    final output = widget.arguments?['output'];
    if (output != null && output.isNotEmpty) return output;
    return null;
  }

  void _openOutputFile() {
    final path = _findOutputPath();
    if (path == null) return;

    final file = File(path);
    final dir = Directory(path);

    if (dir.existsSync()) {
      // Это папка — открываем в проводнике
      Process.run('explorer', [path]);
    } else if (file.existsSync()) {
      // Это файл — открываем папку с выделением файла
      Process.run('explorer', ['/select,', path]);
    } else {
      // Пробуем открыть родительскую папку
      final parent = file.parent;
      if (parent.existsSync()) {
        Process.run('explorer', [parent.path]);
      }
    }
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _statusSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.bgModal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMedium, borderRadius: BorderRadius.circular(2)),
          ),
          _buildHeader(),
          Container(height: 1, color: AppTheme.borderSubtle),
          Expanded(child: _buildConsole()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.command.colorValue.withValues(alpha: 0.2),
                widget.command.colorValue.withValues(alpha: 0.1),
              ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.command.iconData, color: widget.command.colorValue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.command.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.close_circle, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (Color color, String text, IconData icon) = switch (_status) {
      ScriptStatus.idle => (AppTheme.textMuted, 'Ожидание', Iconsax.clock),
      ScriptStatus.running => (AppTheme.accentColor, 'Выполняется', Iconsax.refresh),
      ScriptStatus.success => (AppTheme.successColor, 'Успешно', Iconsax.tick_circle),
      ScriptStatus.error => (AppTheme.errorColor, 'Ошибка', Iconsax.close_circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_status == ScriptStatus.running)
          SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color))
        else
          Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildConsole() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgConsole,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Row(children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 8),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 8),
                _dot(const Color(0xFF27C93F)),
              ]),
              const SizedBox(width: 16),
              Text('Terminal — ${widget.command.scriptPath}',
                  style: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted, fontSize: 12)),
              const Spacer(),
              IconButton(
                onPressed: _outputs.isNotEmpty ? _copyLogs : null,
                icon: Icon(Iconsax.copy, size: 16,
                    color: _outputs.isNotEmpty ? AppTheme.textSecondary : AppTheme.textMuted),
                tooltip: 'Скопировать логи',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () {
                  setState(() => _autoScroll = !_autoScroll);
                  if (_autoScroll) _scrollToBottom();
                },
                icon: Icon(
                  _autoScroll ? Iconsax.arrow_down : Iconsax.pause,
                  size: 16,
                  color: _autoScroll ? AppTheme.accentColor : AppTheme.textMuted,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ]),
          ),
          Expanded(
            child: _outputs.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_status == ScriptStatus.running)
                        const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accentColor))
                      else
                        const Icon(Iconsax.monitor, color: AppTheme.textMuted, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        _status == ScriptStatus.running ? 'Запуск скрипта...' : 'Ожидание...',
                        style: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ]),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _outputs.length,
                    itemBuilder: (context, index) => _buildLine(_outputs[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) =>
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildLine(ScriptOutput output) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${output.timestamp.hour.toString().padLeft(2, '0')}:'
          '${output.timestamp.minute.toString().padLeft(2, '0')}:'
          '${output.timestamp.second.toString().padLeft(2, '0')}',
          style: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(output.text,
              style: GoogleFonts.jetBrainsMono(
                  color: output.isError ? AppTheme.errorColor : const Color(0xFFE0E0E0),
                  fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    final hasOutput = _findOutputPath() != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(children: [
        Text('${_outputs.length} строк',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const Spacer(),

        // Кнопка "Открыть файл"
        if (_status == ScriptStatus.success && hasOutput)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openOutputFile,
              icon: const Icon(Iconsax.folder_open, size: 18),
              label: const Text('Открыть файл'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.2),
                foregroundColor: AppTheme.successColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),

        if (_status == ScriptStatus.running)
          ElevatedButton.icon(
            onPressed: () => widget.scriptRunner.stopScript(),
            icon: const Icon(Iconsax.stop, size: 18),
            label: const Text('Остановить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor.withValues(alpha: 0.2),
              foregroundColor: AppTheme.errorColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.3)),
              ),
            ),
          ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _status == ScriptStatus.running ? null : _runScript,
          icon: const Icon(Iconsax.refresh, size: 18),
          label: const Text('Перезапустить'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }
}