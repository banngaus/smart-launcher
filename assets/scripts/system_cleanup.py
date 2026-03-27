# ═══ Добавить ПЕРЕД main() ═══

def stream_clean(task_ids, admin):
    """Потоковая очистка — JSON на каждую задачу (для UI)"""
    tasks = [t for t in TASKS if t.id in task_ids]
    total_freed = 0

    for i, task in enumerate(tasks):
        if task.admin and not admin:
            print(json.dumps({
                'type': 'skip', 'task': task.id, 'name': task.name,
                'reason': 'no_admin',
                'progress': (i + 1) / len(tasks),
            }), flush=True)
            continue

        print(json.dumps({
            'type': 'start', 'task': task.id, 'name': task.name,
            'index': i, 'total': len(tasks),
            'progress': i / len(tasks),
        }), flush=True)

        try:
            freed, deleted, errors = task.clean_fn()
        except Exception as ex:
            freed, deleted, errors = 0, 0, 1

        total_freed += freed
        print(json.dumps({
            'type': 'done', 'task': task.id, 'name': task.name,
            'freed': freed, 'freed_fmt': fmt(freed),
            'deleted': deleted, 'errors': errors,
            'progress': (i + 1) / len(tasks),
        }), flush=True)

    print(json.dumps({
        'type': 'complete',
        'total_freed': total_freed,
        'total_freed_fmt': fmt(total_freed),
    }), flush=True)


# ═══ Обновлённый main() ═══

def main():
    args = sys.argv[1:]
    mode = 'clean'
    json_mode = '--json' in args

    if '--scan' in args:
        mode = 'scan'
    elif '--full' in args:
        mode = 'full'

    # ── НОВОЕ: фильтр задач ──
    task_filter = None
    if '--tasks' in args:
        idx = args.index('--tasks')
        if idx + 1 < len(args):
            task_filter = set(args[idx + 1].split(','))

    admin = is_admin()

    # ── НОВОЕ: потоковый режим ──
    if '--stream' in args:
        ids = task_filter or {t.id for t in TASKS if t.level != 'aggressive'}
        stream_clean(ids, admin)
        return 0

    results = []

    if not json_mode:
        print("=" * 52)
        print("     SYSTEM CLEANUP v2.0")
        print("=" * 52)
        print()
        if admin:
            print("  [✓] Запущено с правами администратора")
        else:
            print("  [!] Без прав админа — некоторые задачи пропущены")
        print(f"  Режим: {mode.upper()}")
        print()

    total_freed = 0
    total_scanned = 0

    for task in TASKS:
        # Пропуск если не в фильтре
        if task_filter and task.id not in task_filter:
            continue

        # Пропуск агрессивных если не --full и нет фильтра
        if task.level == 'aggressive' and mode != 'full' and not task_filter:
            continue

        if task.admin and not admin:
            if not json_mode:
                print(f"  [SKIP] {task.name} (нужен администратор)")
            results.append({
                'id': task.id, 'name': task.name, 'level': task.level,
                'status': 'skipped', 'reason': 'no_admin',
                'admin_required': task.admin,
                'size': 0, 'size_fmt': '0 B',
            })
            continue

        try:
            size = task.scan_fn()
        except:
            size = 0

        if task.id == 'restore':
            scan_label = f"{size} точек" if size else "нет"
        else:
            scan_label = fmt(size)

        total_scanned += size if task.id != 'restore' else 0

        if mode == 'scan':
            if not json_mode:
                marker = "  " if size == 0 else "▶ "
                print(f"  {marker}[{task.level[:4].upper():4s}] {task.name}: {scan_label}")
            results.append({
                'id': task.id, 'name': task.name, 'level': task.level,
                'status': 'scanned', 'size': size, 'size_fmt': scan_label,
                'admin_required': task.admin,
            })
            continue

        if not json_mode:
            print(f"  Очистка: {task.name}...", end='', flush=True)

        try:
            freed, deleted, errors = task.clean_fn()
        except Exception as ex:
            freed, deleted, errors = 0, 0, 1
            if not json_mode:
                print(f" [ERROR] {ex}")

        total_freed += freed

        if not json_mode:
            status = "OK" if freed > 0 or deleted > 0 else "--"
            extra = f" ({errors} locked)" if errors > 0 else ""
            print(f"\r  [{status}] {task.name}: {fmt(freed)}{extra}")

        results.append({
            'id': task.id, 'name': task.name, 'level': task.level,
            'status': 'cleaned', 'freed': freed, 'freed_fmt': fmt(freed),
            'deleted': deleted, 'errors': errors, 'admin_required': task.admin,
        })

    if json_mode:
        print(json.dumps({
            'mode': mode, 'admin': admin,
            'total_freed': total_freed, 'total_freed_fmt': fmt(total_freed),
            'total_scanned': total_scanned, 'total_scanned_fmt': fmt(total_scanned),
            'tasks': results,
        }))
    else:
        print()
        print("─" * 52)
        if mode == 'scan':
            print(f"  Можно освободить: {fmt(total_scanned)}")
        else:
            print(f"  Освобождено: {fmt(total_freed)}")
        print("[OK] Cleanup complete!")

    return 0