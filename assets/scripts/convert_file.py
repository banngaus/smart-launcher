"""
Universal File Converter
Использование:
  python convert_file.py --input="path/to/file.png" --output="path/to/file.jpg" --quality=85
"""

import argparse
import os
import sys
import time
import subprocess
import shutil


def get_file_size_str(path):
    """Человекочитаемый размер файла"""
    size = os.path.getsize(path)
    for unit in ['Б', 'КБ', 'МБ', 'ГБ']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} ТБ"


def find_ffmpeg():
    """Ищем FFmpeg"""
    # Рядом с Python (embedded)
    python_dir = os.path.dirname(sys.executable)
    ffmpeg_path = os.path.join(python_dir, 'ffmpeg.exe')
    if os.path.exists(ffmpeg_path):
        return ffmpeg_path

    # В PATH
    ffmpeg_in_path = shutil.which('ffmpeg')
    if ffmpeg_in_path:
        return ffmpeg_in_path

    return None


def convert_image(input_path, output_path, quality=85):
    """Конвертация изображений через Pillow"""
    try:
        from PIL import Image
    except ImportError:
        print("❌ Pillow не установлен!")
        print("   Установите: pip install Pillow")
        sys.exit(1)

    print(f"🖼  Конвертация изображения...")
    print(f"   Исходный: {os.path.basename(input_path)}")
    print(f"   Размер:   {get_file_size_str(input_path)}")
    print()

    img = Image.open(input_path)

    # Информация
    print(f"   Разрешение: {img.width}x{img.height}")
    print(f"   Режим:      {img.mode}")
    print()

    out_ext = os.path.splitext(output_path)[1].lower()

    # Конвертируем режим если нужно
    if out_ext in ['.jpg', '.jpeg']:
        if img.mode in ('RGBA', 'P', 'LA'):
            print("   ℹ️  Удаление прозрачности (JPEG не поддерживает альфа-канал)")
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if 'A' in img.mode else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')

    elif out_ext == '.ico':
        # ICO поддерживает определённые размеры
        sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
        img.save(output_path, format='ICO', sizes=sizes)
        print(f"✅ Сохранено: {os.path.basename(output_path)}")
        print(f"   Размер: {get_file_size_str(output_path)}")
        return

    # Сохраняем
    save_kwargs = {}
    if out_ext in ['.jpg', '.jpeg']:
        save_kwargs['quality'] = quality
        save_kwargs['optimize'] = True
    elif out_ext == '.png':
        save_kwargs['optimize'] = True
    elif out_ext == '.webp':
        save_kwargs['quality'] = quality

    img.save(output_path, **save_kwargs)

    print(f"✅ Сохранено: {os.path.basename(output_path)}")
    print(f"   Размер: {get_file_size_str(output_path)}")

    # Сравнение размеров
    orig_size = os.path.getsize(input_path)
    new_size = os.path.getsize(output_path)
    if new_size < orig_size:
        saved = ((orig_size - new_size) / orig_size) * 100
        print(f"   📉 Сжатие: -{saved:.1f}%")
    elif new_size > orig_size:
        increase = ((new_size - orig_size) / orig_size) * 100
        print(f"   📈 Увеличение: +{increase:.1f}%")


def convert_audio_video(input_path, output_path, quality=None):
    """Конвертация аудио/видео через FFmpeg"""
    ffmpeg = find_ffmpeg()

    if not ffmpeg:
        print("❌ FFmpeg не найден!")
        print("   Установите FFmpeg или запустите setup_python.bat")
        sys.exit(1)

    out_ext = os.path.splitext(output_path)[1].lower()
    in_ext = os.path.splitext(input_path)[1].lower()

    # Определяем тип
    audio_exts = ['.mp3', '.wav', '.flac', '.ogg', '.aac', '.m4a', '.wma']
    video_exts = ['.mp4', '.avi', '.mkv', '.mov', '.webm', '.gif']

    is_audio = out_ext in audio_exts
    is_video = out_ext in video_exts

    if is_audio:
        print(f"🎵 Конвертация аудио...")
    else:
        print(f"🎬 Конвертация видео...")

    print(f"   Исходный: {os.path.basename(input_path)}")
    print(f"   Размер:   {get_file_size_str(input_path)}")
    print()

    # Формируем команду FFmpeg
    cmd = [ffmpeg, '-i', input_path, '-y']  # -y = перезаписывать

    if out_ext == '.mp3':
        bitrate = quality if quality else '192'
        cmd.extend(['-codec:a', 'libmp3lame', '-b:a', f'{bitrate}k'])
    elif out_ext == '.flac':
        cmd.extend(['-codec:a', 'flac'])
    elif out_ext == '.wav':
        cmd.extend(['-codec:a', 'pcm_s16le'])
    elif out_ext == '.ogg':
        q = quality if quality else '5'
        cmd.extend(['-codec:a', 'libvorbis', '-q:a', str(q)])
    elif out_ext == '.aac':
        bitrate = quality if quality else '192'
        cmd.extend(['-codec:a', 'aac', '-b:a', f'{bitrate}k'])
    elif out_ext == '.m4a':
        bitrate = quality if quality else '192'
        cmd.extend(['-codec:a', 'aac', '-b:a', f'{bitrate}k'])
    elif out_ext == '.mp4':
        cmd.extend(['-codec:v', 'libx264', '-preset', 'medium',
                    '-crf', str(quality if quality else '23'),
                    '-codec:a', 'aac', '-b:a', '192k'])
    elif out_ext == '.avi':
        cmd.extend(['-codec:v', 'mpeg4', '-q:v', str(quality if quality else '5'),
                    '-codec:a', 'mp3', '-b:a', '192k'])
    elif out_ext == '.mkv':
        cmd.extend(['-codec:v', 'libx264', '-preset', 'medium',
                    '-crf', str(quality if quality else '23'),
                    '-codec:a', 'aac'])
    elif out_ext == '.mov':
        cmd.extend(['-codec:v', 'libx264', '-preset', 'medium',
                    '-crf', str(quality if quality else '23'),
                    '-codec:a', 'aac'])
    elif out_ext == '.webm':
        cmd.extend(['-codec:v', 'libvpx-vp9', '-crf', str(quality if quality else '30'),
                    '-b:v', '0', '-codec:a', 'libopus'])
    elif out_ext == '.gif':
        cmd.extend(['-vf', 'fps=15,scale=480:-1:flags=lanczos',
                    '-loop', '0'])

    cmd.append(output_path)

    print(f"   ⏳ Обработка...")
    print()

    # Запускаем FFmpeg
    process = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    if process.returncode == 0:
        print(f"✅ Сохранено: {os.path.basename(output_path)}")
        print(f"   Размер: {get_file_size_str(output_path)}")

        orig_size = os.path.getsize(input_path)
        new_size = os.path.getsize(output_path)
        if new_size < orig_size:
            saved = ((orig_size - new_size) / orig_size) * 100
            print(f"   📉 Сжатие: -{saved:.1f}%")
    else:
        print(f"❌ Ошибка FFmpeg:")
        # Выводим последние строки stderr
        errors = process.stderr.strip().split('\n')
        for line in errors[-5:]:
            print(f"   {line}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Universal File Converter")
    parser.add_argument("--input", required=True, help="Входной файл")
    parser.add_argument("--output", required=True, help="Выходной файл")
    parser.add_argument("--quality", type=int, default=None, help="Качество")

    args = parser.parse_args()

    print("=" * 50)
    print("🔄 SmartLauncher File Converter")
    print("=" * 50)
    print()

    if not os.path.exists(args.input):
        print(f"❌ Файл не найден: {args.input}")
        sys.exit(1)

    # Определяем тип конвертации
    in_ext = os.path.splitext(args.input)[1].lower()
    out_ext = os.path.splitext(args.output)[1].lower()

    image_exts = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.tiff', '.tif', '.ico']
    audio_exts = ['.mp3', '.wav', '.flac', '.ogg', '.aac', '.m4a', '.wma']
    video_exts = ['.mp4', '.avi', '.mkv', '.mov', '.webm', '.gif']

    start_time = time.time()

    if in_ext in image_exts and out_ext in image_exts:
        convert_image(args.input, args.output, quality=args.quality or 85)
    elif in_ext in audio_exts + video_exts or out_ext in audio_exts + video_exts:
        convert_audio_video(args.input, args.output, quality=args.quality)
    else:
        print(f"❌ Неподдерживаемая конвертация: {in_ext} → {out_ext}")
        sys.exit(1)

    elapsed = time.time() - start_time
    print()
    print("=" * 50)
    print(f"⏱  Время: {elapsed:.1f}с")
    print("=" * 50)


if __name__ == "__main__":
    main()