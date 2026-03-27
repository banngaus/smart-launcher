"""
Создание GIF из видео или изображений
Использование: python create_gif.py --input="video.mp4" --fps=15 --width=480
"""

import argparse
import os
import shutil
import subprocess
import sys
import time


def find_ffmpeg():
    python_dir = os.path.dirname(sys.executable)
    ffmpeg_path = os.path.join(python_dir, 'ffmpeg.exe')
    if os.path.exists(ffmpeg_path):
        return ffmpeg_path
    ffmpeg_in_path = shutil.which('ffmpeg')
    if ffmpeg_in_path:
        return ffmpeg_in_path
    return None


def format_size(size):
    for unit in ['Б', 'КБ', 'МБ', 'ГБ']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} ТБ"


def create_gif_from_video(input_path, fps, width):
    """GIF из видео через FFmpeg"""
    ffmpeg = find_ffmpeg()

    if not ffmpeg:
        print("❌ FFmpeg не найден!")
        sys.exit(1)

    print(f"🎬 Видео: {os.path.basename(input_path)}")
    print(f"   Размер: {format_size(os.path.getsize(input_path))}")
    print(f"   FPS: {fps}")
    print(f"   Ширина: {width}px")
    print()

    base_name = os.path.splitext(input_path)[0]
    output_path = f"{base_name}.gif"

    counter = 1
    while os.path.exists(output_path):
        output_path = f"{base_name}_gif_{counter}.gif"
        counter += 1

    # Двухпроходное создание GIF для лучшего качества
    palette_path = f"{base_name}_palette.png"

    print("⏳ Шаг 1/2: Генерация палитры...")
    
    # Генерируем палитру
    cmd_palette = [
        ffmpeg, '-i', input_path, '-y',
        '-vf', f'fps={fps},scale={width}:-1:flags=lanczos,palettegen=stats_mode=diff',
        palette_path
    ]

    subprocess.run(
        cmd_palette,
        capture_output=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    print("⏳ Шаг 2/2: Создание GIF...")

    if os.path.exists(palette_path):
        # Используем палитру
        cmd_gif = [
            ffmpeg, '-i', input_path, '-i', palette_path, '-y',
            '-lavfi', f'fps={fps},scale={width}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5',
            '-loop', '0',
            output_path
        ]
    else:
        # Без палитры (fallback)
        cmd_gif = [
            ffmpeg, '-i', input_path, '-y',
            '-vf', f'fps={fps},scale={width}:-1:flags=lanczos',
            '-loop', '0',
            output_path
        ]

    start_time = time.time()
    
    process = subprocess.run(
        cmd_gif,
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    # Удаляем палитру
    if os.path.exists(palette_path):
        os.remove(palette_path)

    elapsed = time.time() - start_time

    if process.returncode == 0 and os.path.exists(output_path):
        output_size = os.path.getsize(output_path)
        print()
        print(f"✅ GIF создан!")
        print(f"   Файл: {os.path.basename(output_path)}")
        print(f"   Размер: {format_size(output_size)}")
        print(f"   Время: {elapsed:.1f}с")
    else:
        print("❌ Ошибка создания GIF:")
        errors = process.stderr.strip().split('\n')
        for line in errors[-5:]:
            print(f"   {line}")
        sys.exit(1)


def create_gif_from_images(input_dir, fps, width):
    """GIF из папки с изображениями через Pillow"""
    try:
        from PIL import Image
    except ImportError:
        print("❌ Pillow не установлен!")
        sys.exit(1)

    image_exts = {'.png', '.jpg', '.jpeg', '.bmp', '.webp'}
    images = sorted([
        os.path.join(input_dir, f) for f in os.listdir(input_dir)
        if os.path.splitext(f)[1].lower() in image_exts
    ])

    if not images:
        print("❌ Изображения не найдены в папке!")
        sys.exit(1)

    print(f"📂 Папка: {input_dir}")
    print(f"   Найдено кадров: {len(images)}")
    print(f"   FPS: {fps}")
    print(f"   Ширина: {width}px")
    print()

    output_path = os.path.join(input_dir, 'animation.gif')
    counter = 1
    while os.path.exists(output_path):
        output_path = os.path.join(input_dir, f'animation_{counter}.gif')
        counter += 1

    print("⏳ Создание GIF...")
    start_time = time.time()

    frames = []
    for i, img_path in enumerate(images):
        img = Image.open(img_path)
        
        # Ресайз
        ratio = width / img.width
        new_h = int(img.height * ratio)
        img = img.resize((width, new_h), Image.Resampling.LANCZOS)
        
        # Конвертируем в RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        frames.append(img)
        
        if (i + 1) % 10 == 0:
            print(f"   Обработано: {i + 1}/{len(images)}")

    duration = int(1000 / fps)  # мс на кадр
    
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        optimize=True
    )

    elapsed = time.time() - start_time
    output_size = os.path.getsize(output_path)

    print()
    print(f"✅ GIF создан!")
    print(f"   Файл: {os.path.basename(output_path)}")
    print(f"   Кадров: {len(frames)}")
    print(f"   Размер: {format_size(output_size)}")
    print(f"   Время: {elapsed:.1f}с")


def main():
    parser = argparse.ArgumentParser(description="Create GIF")
    parser.add_argument("--input", required=True, help="Видеофайл или папка с изображениями")
    parser.add_argument("--fps", type=int, default=15, help="Кадров в секунду")
    parser.add_argument("--width", type=int, default=480, help="Ширина в пикселях")

    args = parser.parse_args()

    print("=" * 50)
    print("🎞️  SmartLauncher — Создание GIF")
    print("=" * 50)
    print()

    if not os.path.exists(args.input):
        print(f"❌ Не найдено: {args.input}")
        sys.exit(1)

    if os.path.isdir(args.input):
        create_gif_from_images(args.input, args.fps, args.width)
    else:
        create_gif_from_video(args.input, args.fps, args.width)

    print()
    print("=" * 50)


if __name__ == "__main__":
    main()