"""
Извлечение аудио из видео
Использование: python extract_audio.py --input="video.mp4" --format=mp3
"""

import argparse
import os
import shutil
import subprocess
import sys
import time


def find_ffmpeg():
    """Ищем FFmpeg"""
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


def extract_audio(input_path, audio_format):
    """Извлечение аудио"""
    ffmpeg = find_ffmpeg()

    if not ffmpeg:
        print("❌ FFmpeg не найден!")
        print("   Установите FFmpeg или запустите setup_embedded_python.bat")
        sys.exit(1)

    print(f"🎬 Видео: {os.path.basename(input_path)}")
    print(f"   Размер: {format_size(os.path.getsize(input_path))}")
    print(f"   Формат аудио: {audio_format.upper()}")
    print()

    # Формируем выходной путь
    base_name = os.path.splitext(input_path)[0]
    output_path = f"{base_name}.{audio_format}"
    
    counter = 1
    while os.path.exists(output_path):
        output_path = f"{base_name}_audio_{counter}.{audio_format}"
        counter += 1

    # Формируем команду
    cmd = [ffmpeg, '-i', input_path, '-y', '-vn']  # -vn = без видео

    if audio_format == 'mp3':
        cmd.extend(['-codec:a', 'libmp3lame', '-b:a', '320k', '-q:a', '0'])
    elif audio_format == 'wav':
        cmd.extend(['-codec:a', 'pcm_s16le'])
    elif audio_format == 'flac':
        cmd.extend(['-codec:a', 'flac'])
    elif audio_format == 'aac':
        cmd.extend(['-codec:a', 'aac', '-b:a', '256k'])
    elif audio_format == 'ogg':
        cmd.extend(['-codec:a', 'libvorbis', '-q:a', '8'])

    cmd.append(output_path)

    print("⏳ Извлечение аудио...")
    print()

    start_time = time.time()

    process = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )

    elapsed = time.time() - start_time

    if process.returncode == 0 and os.path.exists(output_path):
        output_size = os.path.getsize(output_path)
        print(f"✅ Аудио извлечено!")
        print(f"   Файл: {os.path.basename(output_path)}")
        print(f"   Размер: {format_size(output_size)}")
        print(f"   Время: {elapsed:.1f}с")
    else:
        print("❌ Ошибка извлечения:")
        errors = process.stderr.strip().split('\n')
        for line in errors[-5:]:
            print(f"   {line}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Extract Audio from Video")
    parser.add_argument("--input", required=True, help="Входной видеофайл")
    parser.add_argument("--format", default="mp3", 
                       choices=['mp3', 'wav', 'flac', 'aac', 'ogg'],
                       help="Формат аудио")

    args = parser.parse_args()

    print("=" * 50)
    print("🎵 SmartLauncher — Извлечение аудио")
    print("=" * 50)
    print()

    if not os.path.isfile(args.input):
        print(f"❌ Файл не найден: {args.input}")
        sys.exit(1)

    extract_audio(args.input, args.format)

    print()
    print("=" * 50)


if __name__ == "__main__":
    main()