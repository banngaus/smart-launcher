"""
Power Manager — единый скрипт управления питанием
Использование:
  python power_manager.py --action=shutdown --minutes=60
  python power_manager.py --action=sleep
  python power_manager.py --action=cancel
  python power_manager.py --action=restart
  python power_manager.py --action=hibernate
"""

import argparse
import subprocess
import sys
import os
import ctypes


def is_admin():
    """Проверка прав администратора"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def shutdown_timer(minutes):
    """Выключение по таймеру"""
    seconds = int(minutes) * 60
    print(f"⏱  Установка таймера выключения: {minutes} мин ({seconds} сек)")
    print()

    # Сначала отменяем предыдущий таймер если есть
    subprocess.run(
        ["shutdown", "/a"],
        capture_output=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    result = subprocess.run(
        ["shutdown", "/s", "/t", str(seconds)],
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    if result.returncode == 0:
        hours = minutes // 60
        mins = minutes % 60
        time_str = ""
        if hours > 0:
            time_str += f"{hours} ч "
        if mins > 0:
            time_str += f"{mins} мин"

        print(f"✅ Таймер установлен!")
        print(f"   ПК выключится через: {time_str.strip()}")
        print()
        print(f"   Для отмены используйте действие 'Отмена выключения'")
    else:
        print(f"❌ Ошибка: {result.stderr.strip()}")
        sys.exit(1)


def cancel_shutdown():
    """Отмена запланированного выключения/перезагрузки"""
    print("🚫 Отмена запланированного выключения...")
    print()

    result = subprocess.run(
        ["shutdown", "/a"],
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    if result.returncode == 0:
        print("✅ Выключение/перезагрузка отменены!")
    else:
        error = result.stderr.strip()
        if "невозможно прервать" in error.lower() or "unable to abort" in error.lower():
            print("ℹ️  Нет запланированных выключений для отмены")
        else:
            print(f"⚠️  {error}")
            print("   Возможно, выключение не было запланировано")


def sleep_pc():
    """Перевод ПК в режим сна"""
    print("😴 Перевод ПК в режим сна...")
    print()

    if os.name == 'nt':
        # Отключаем гибернацию чтобы был именно сон, а не гибернация
        subprocess.run(
            ["powercfg", "-h", "off"],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )

        result = subprocess.run(
            ["rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0"],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )

        if result.returncode == 0:
            print("✅ Команда сна отправлена")
        else:
            print(f"❌ Ошибка: {result.stderr.strip()}")
            sys.exit(1)
    else:
        print("❌ Режим сна поддерживается только на Windows")
        sys.exit(1)


def restart_pc(minutes=0):
    """Перезагрузка ПК"""
    seconds = int(minutes) * 60

    if seconds > 0:
        print(f"🔄 Перезагрузка через {minutes} мин ({seconds} сек)...")
    else:
        print("🔄 Перезагрузка ПК...")
    print()

    # Отменяем предыдущий таймер
    subprocess.run(
        ["shutdown", "/a"],
        capture_output=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    result = subprocess.run(
        ["shutdown", "/r", "/t", str(seconds)],
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    if result.returncode == 0:
        if seconds > 0:
            print(f"✅ Перезагрузка запланирована через {minutes} мин")
        else:
            print("✅ ПК перезагружается...")
        print(f"   Для отмены используйте действие 'Отмена'")
    else:
        print(f"❌ Ошибка: {result.stderr.strip()}")
        sys.exit(1)


def hibernate_pc():
    """Гибернация ПК"""
    print("💤 Перевод ПК в гибернацию...")
    print()

    if os.name == 'nt':
        # Включаем гибернацию
        subprocess.run(
            ["powercfg", "-h", "on"],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )

        result = subprocess.run(
            ["shutdown", "/h"],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )

        if result.returncode == 0:
            print("✅ Команда гибернации отправлена")
        else:
            error = result.stderr.strip()
            if "гибернац" in error.lower() or "hibernate" in error.lower():
                print("❌ Гибернация не поддерживается или отключена")
                print("   Попробуйте включить: powercfg -h on")
            else:
                print(f"❌ Ошибка: {error}")
            sys.exit(1)
    else:
        print("❌ Гибернация поддерживается только на Windows")
        sys.exit(1)


def lock_pc():
    """Блокировка ПК"""
    print("🔒 Блокировка ПК...")
    print()

    if os.name == 'nt':
        result = subprocess.run(
            ["rundll32.exe", "user32.dll,LockWorkStation"],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )

        if result.returncode == 0:
            print("✅ ПК заблокирован")
        else:
            print(f"❌ Ошибка: {result.stderr.strip()}")
            sys.exit(1)
    else:
        print("❌ Блокировка поддерживается только на Windows")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Power Manager")
    parser.add_argument(
        "--action",
        required=True,
        choices=["shutdown", "sleep", "cancel", "restart", "hibernate", "lock"],
        help="Действие"
    )
    parser.add_argument(
        "--minutes",
        type=int,
        default=0,
        help="Минуты (для shutdown и restart)"
    )

    args = parser.parse_args()

    print("=" * 50)
    print("⚡ Power Manager")
    print("=" * 50)
    print()

    actions = {
        "shutdown": lambda: shutdown_timer(args.minutes) if args.minutes > 0
                            else shutdown_timer(1),
        "sleep": sleep_pc,
        "cancel": cancel_shutdown,
        "restart": lambda: restart_pc(args.minutes),
        "hibernate": hibernate_pc,
        "lock": lock_pc,
    }

    action_func = actions.get(args.action)
    if action_func:
        action_func()
    else:
        print(f"❌ Неизвестное действие: {args.action}")
        sys.exit(1)

    print()
    print("=" * 50)
    print("✅ Готово!")
    print("=" * 50)


if __name__ == "__main__":
    main()