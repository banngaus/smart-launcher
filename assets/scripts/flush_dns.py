#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, subprocess, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def print_header():
    print("=" * 44)
    print("        FLUSH DNS CACHE")
    print("=" * 44)
    print()

def main():
    print_header()
    
    print("[...] Flushing DNS cache...")
    print()
    
    try:
        result = subprocess.run(['ipconfig', '/flushdns'], capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
        
        if result.returncode == 0:
            print("[OK] DNS cache flushed successfully!")
        else:
            print(f"[ERROR] {result.stderr}")
            return 1
    except Exception as e:
        print(f"[ERROR] {e}")
        return 1
    
    print()
    print("[...] Renewing IP address...")
    
    try:
        subprocess.run(['ipconfig', '/release'], capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
        subprocess.run(['ipconfig', '/renew'], capture_output=True, text=True, creationflags=subprocess.CREATE_NO_WINDOW)
        print("[OK] IP address renewed!")
    except Exception as e:
        print(f"[!] IP renewal error: {e}")
    
    print()
    print("[OK] Network settings reset successfully!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
