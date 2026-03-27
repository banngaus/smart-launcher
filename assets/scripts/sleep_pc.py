#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, subprocess, time, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def print_header():
    print("=" * 44)
    print("        SLEEP MODE")
    print("=" * 44)
    print()

def sleep_pc():
    print("[...] Preparing to enter sleep mode...")
    print()
    
    for i in range(3, 0, -1):
        print(f"   Sleep in {i}...")
        time.sleep(1)
    
    print()
    print("[...] Entering sleep mode...")
    
    try:
        subprocess.run(['rundll32.exe', 'powrprof.dll,SetSuspendState', '0', '1', '0'], capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
        print("[OK] Sleep mode activated!")
    except Exception as e:
        print(f"[ERROR] {e}")

def main():
    print_header()
    
    print("[INFO] You are about to put your PC to sleep")
    print()
    print("   All unsaved data may be lost!")
    print()
    confirm = input("Continue? (y/n): ").strip().lower()
    
    if confirm == 'y':
        return sleep_pc()
    else:
        print("[OK] Operation cancelled")
        return 0

if __name__ == "__main__":
    sys.exit(main())
