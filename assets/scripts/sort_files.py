"""
Сортировка файлов по типу
Использование: python sort_files.py --path="C:\\Users\\User\\Downloads"
"""

import argparse
import os
import shutil
import sys

# ═══ FIX: принудительный UTF-8 вывод ═══
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')


# Категории файлов
FILE_CATEGORIES = {
    'Изображения': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg',
                     '.tiff', '.ico', '.raw', '.psd', '.ai'],
    'Видео': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
              '.m4v', '.mpg', '.mpeg', '.3gp'],
    'Аудио': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a',
              '.opus', '.aiff'],
    'Документы': ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
                   '.txt', '.rtf', '.odt', '.ods', '.odp', '.csv'],
    'Архивы': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.iso'],
    'Программы': ['.exe', '.msi', '.dmg', '.deb', '.rpm', '.appimage'],
    'Код': ['.py', '.js', '.ts', '.html', '.css', '.java', '.cpp', '.c',
            '.h', '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt',
            '.dart', '.json', '.xml', '.yaml', '.yml', '.toml', '.ini',
            '.sh', '.bat', '.ps1', '.sql'],
    'Шрифты': ['.ttf', '.otf', '.woff', '.woff2', '.eot'],
    'Торренты': ['.torrent'],
    'Базы данных': ['.db', '.sqlite', '.sqlite3', '.mdb'],
}


def sort_files(path):
    """Сортировка файлов по папкам"""
    print(f"[ПАПКА] {path}")
    print()

    if not os.path.isdir(path):
        print(f"[ОШИБКА] Папка не найдена: {path}")
        sys.exit(1)

    # Считаем файлы
    files = [f for f in os.listdir(path)
             if os.path.isfile(os.path.join(path, f))]

    if not files:
        print("[INFO] Папка пуста -- нечего сортировать!")
        return

    print(f"[INFO] Найдено файлов: {len(files)}")
    print()

    moved = 0
    skipped = 0
    stats = {}

    for filename in files:
        filepath = os.path.join(path, filename)
        ext = os.path.splitext(filename)[1].lower()

        # Определяем категорию
        category = None
        for cat_name, extensions in FILE_CATEGORIES.items():
            if ext in extensions:
                category = cat_name
                break

        if category is None:
            if ext:
                category = 'Другое'
            else:
                skipped += 1
                continue

        # Создаём папку категории
        cat_dir = os.path.join(path, category)
        os.makedirs(cat_dir, exist_ok=True)

        # Перемещаем файл
        dest = os.path.join(cat_dir, filename)

        # Если файл с таким именем уже есть
        if os.path.exists(dest):
            base, extension = os.path.splitext(filename)
            counter = 1
            while os.path.exists(dest):
                dest = os.path.join(cat_dir, f"{base}_{counter}{extension}")
                counter += 1

        try:
            shutil.move(filepath, dest)
            moved += 1
            stats[category] = stats.get(category, 0) + 1
            print(f"   [OK] {filename} -> {category}/")
        except Exception as e:
            print(f"   [ERR] {filename}: {e}")
            skipped += 1

    print()
    print("=" * 50)
    print("[РЕЗУЛЬТАТ]")
    print("-" * 50)

    for category, count in sorted(stats.items(), key=lambda x: x[1], reverse=True):
        print(f"   {category}: {count} файлов")

    print("-" * 50)
    print(f"   Перемещено: {moved}")
    print(f"   Пропущено: {skipped}")
    print("=" * 50)


def main():
    parser = argparse.ArgumentParser(description="Sort Files by Type")
    parser.add_argument("--path", required=True, help="Папка для сортировки")

    args = parser.parse_args()

    print("=" * 50)
    print("SmartLauncher -- Сортировка файлов")
    print("=" * 50)
    print()

    sort_files(args.path)

    print()
    print("[OK] Сортировка завершена!")


if __name__ == "__main__":
    main()