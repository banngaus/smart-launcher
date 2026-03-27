"""
Пакетное изменение размера изображений
Использование: python batch_resize.py --path="C:\Photos" --width=1920 --quality=85
"""

import argparse
import os
import sys
import time


def format_size(size):
    for unit in ['Б', 'КБ', 'МБ', 'ГБ']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} ТБ"


def batch_resize(path, max_width, quality):
    """Ресайз всех изображений в папке"""
    try:
        from PIL import Image
    except ImportError:
        print("❌ Pillow не установлен!")
        print("   Установите: pip install Pillow")
        sys.exit(1)

    print(f"📂 Папка: {path}")
    print(f"   Макс. ширина: {max_width}px")
    print(f"   Качество: {quality}%")
    print()

    if not os.path.isdir(path):
        print(f"❌ Папка не найдена: {path}")
        sys.exit(1)

    # Создаём папку для результатов
    output_dir = os.path.join(path, '_resized')
    os.makedirs(output_dir, exist_ok=True)

    image_extensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff'}
    
    files = [f for f in os.listdir(path) 
             if os.path.isfile(os.path.join(path, f)) and 
             os.path.splitext(f)[1].lower() in image_extensions]

    if not files:
        print("📭 Изображения не найдены!")
        return

    print(f"🖼️  Найдено изображений: {len(files)}")
    print()

    processed = 0
    skipped = 0
    total_original = 0
    total_new = 0
    start_time = time.time()

    for i, filename in enumerate(files, 1):
        filepath = os.path.join(path, filename)
        
        try:
            img = Image.open(filepath)
            original_size = os.path.getsize(filepath)
            total_original += original_size

            w, h = img.size
            
            # Пропускаем если уже меньше
            if w <= max_width:
                print(f"   ⏭️  [{i}/{len(files)}] {filename} — уже {w}x{h}")
                skipped += 1
                continue

            # Вычисляем новый размер с сохранением пропорций
            ratio = max_width / w
            new_w = max_width
            new_h = int(h * ratio)

            img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

            # Конвертируем RGBA в RGB для JPEG
            ext = os.path.splitext(filename)[1].lower()
            if ext in ['.jpg', '.jpeg'] and img_resized.mode in ('RGBA', 'P'):
                background = Image.new('RGB', img_resized.size, (255, 255, 255))
                if img_resized.mode == 'P':
                    img_resized = img_resized.convert('RGBA')
                background.paste(img_resized, mask=img_resized.split()[-1])
                img_resized = background

            # Сохраняем
            output_path = os.path.join(output_dir, filename)
            
            save_kwargs = {}
            if ext in ['.jpg', '.jpeg']:
                save_kwargs = {'quality': quality, 'optimize': True}
            elif ext == '.png':
                save_kwargs = {'optimize': True}
            elif ext == '.webp':
                save_kwargs = {'quality': quality}

            img_resized.save(output_path, **save_kwargs)
            
            new_size = os.path.getsize(output_path)
            total_new += new_size
            
            saved_pct = ((original_size - new_size) / original_size * 100)
            
            print(f"   ✅ [{i}/{len(files)}] {filename}: "
                  f"{w}x{h} → {new_w}x{new_h} | "
                  f"{format_size(original_size)} → {format_size(new_size)} "
                  f"(-{saved_pct:.0f}%)")
            
            processed += 1
            img.close()

        except Exception as e:
            print(f"   ❌ [{i}/{len(files)}] {filename}: {e}")

    elapsed = time.time() - start_time
    
    print()
    print("=" * 60)
    print("📊 Результат:")
    print(f"   ✅ Обработано: {processed}")
    print(f"   ⏭️  Пропущено: {skipped}")
    if total_original > 0 and total_new > 0:
        saved = total_original - total_new
        saved_pct = (saved / total_original * 100)
        print(f"   📦 Исходный размер: {format_size(total_original)}")
        print(f"   📦 Новый размер: {format_size(total_new)}")
        print(f"   📉 Сэкономлено: {format_size(saved)} (-{saved_pct:.1f}%)")
    print(f"   ⏱️  Время: {elapsed:.1f}с")
    print(f"   📁 Результаты: {output_dir}")
    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Batch Resize Images")
    parser.add_argument("--path", required=True, help="Папка с изображениями")
    parser.add_argument("--width", type=int, default=1920, help="Макс. ширина")
    parser.add_argument("--quality", type=int, default=85, help="Качество")

    args = parser.parse_args()

    print("=" * 60)
    print("🖼️  SmartLauncher — Пакетный ресайз")
    print("=" * 60)
    print()

    batch_resize(args.path, args.width, args.quality)

    print()
    print("✅ Ресайз завершён!")


if __name__ == "__main__":
    main()