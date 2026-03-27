#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, subprocess, io, os, shutil, tempfile

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def print_header():
    print("=" * 44)
    print("        CLEAN TEMP FILES")
    print("=" * 44)
    print()

def get_size(path):
    total = 0
    try:
        for dp, dn, fn in os.walk(path):
            for f in fn:
                try: total += os.path.getsize(os.path.join(dp, f))
                except: pass
    except: pass
    return total

def clean(path, name):
    if not os.path.exists(path):
        print(f"  [--] {name}: not found")
        return 0
    before = get_size(path)
    deleted = 0
    try:
        for item in os.listdir(path):
            p = os.path.join(path, item)
            try:
                if os.path.isfile(p): os.remove(p)
                else: shutil.rmtree(p, ignore_errors=True)
                deleted += 1
            except: pass
    except: pass
    freed = before - get_size(path)
    status = "[OK]" if freed > 0 else "[--]"
    print(f"  {status} {name}: freed {freed/1024/1024:.1f}MB")
    return freed

def main():
    print_header()
    
    total = 0
    total += clean(tempfile.gettempdir(), "User TEMP")
    total += clean(os.path.join(os.environ.get('SYSTEMROOT','C:\\Windows'), 'Temp'), "Windows TEMP")
    
    print()
    print(f"[TOTAL] Freed: {total/1024/1024:.1f}MB")
    print("[OK] Cleanup complete!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
