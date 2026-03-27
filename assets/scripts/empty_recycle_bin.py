#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, subprocess, io, ctypes
from ctypes import windll, Structure, byref, sizeof
from ctypes.wintypes import DWORD

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def print_header():
    print("=" * 44)
    print("        EMPTY RECYCLE BIN")
    print("=" * 44)
    print()

def get_recycle_bin_size():
    try:
        class SHQUERYRBINFO(Structure):
            _fields_ = [("cbSize", DWORD), ("i64Size", ctypes.c_int64), ("i64NumItems", ctypes.c_int64)]
        
        info = SHQUERYRBINFO()
        info.cbSize = sizeof(SHQUERYRBINFO)
        result = windll.shell32.SHQueryRecycleBinW(None, byref(info))
        
        if result == 0:
            return info.i64Size, info.i64NumItems
    except:
        pass
    return 0, 0

def main():
    print_header()
    
    size, items = get_recycle_bin_size()
    
    print(f"[INFO] Current recycle bin status:")
    print(f"   Files: {items}")
    print(f"   Size: {size/1024/1024:.2f} MB")
    print()
    
    if items == 0:
        print("[OK] Recycle bin is already empty!")
        return 0
    
    print("[...] Emptying recycle bin...")
    
    try:
        result = windll.shell32.SHEmptyRecycleBinW(None, None, 7)
        if result == 0:
            print("[OK] Recycle bin emptied successfully!")
            print(f"   Freed: {size/1024/1024:.2f} MB")
            print(f"   Deleted files: {items}")
        else:
            print("[ERROR] Failed to empty recycle bin")
            return 1
    except Exception as e:
        print(f"[ERROR] {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
