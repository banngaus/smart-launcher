#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys, subprocess, io, re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def get_processes():
    processes = []
    try:
        result = subprocess.run(
            ['tasklist', '/FO', 'CSV', '/NH'],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        
        output = result.stdout.decode('cp866', errors='replace')
        
        for line in output.strip().split('\n'):
            if line:
                parts = line.replace('"', '').split(',')
                if len(parts) >= 5:
                    name = parts[0].strip()
                    pid = parts[1].strip()
                    mem_str = parts[4].strip()
                    mem_num = re.sub(r'[^\d]', '', mem_str)
                    mem_kb = int(mem_num) if mem_num else 0
                    
                    if name and pid.isdigit():
                        processes.append({
                            'name': name,
                            'pid': pid,
                            'mem_kb': mem_kb,
                        })
    except Exception as e:
        print(f"[ERROR] {e}")
    
    return processes

def kill_by_name(name):
    print(f"[...] Killing process: {name}")
    
    try:
        result = subprocess.run(['taskkill', '/F', '/IM', name], capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
        if result.returncode == 0:
            print(f"[OK] Process '{name}' terminated successfully!")
            return True
        else:
            print(f"[ERROR] Failed to kill '{name}'")
            return False
    except Exception as e:
        print(f"[ERROR] {e}")
        return False

def main():
    print("=" * 44)
    print("        KILL PROCESS")
    print("=" * 44)
    print()
    
    target_name = None
    for arg in sys.argv[1:]:
        if arg.startswith('--name='):
            target_name = arg.split('=', 1)[1]
    
    if target_name:
        success = kill_by_name(target_name)
        return success ? 0 : 1
    
    print("[INFO] Top processes by memory:")
    print()
    
    processes = get_processes()
    processes_sorted = sorted(processes, key=lambda x: x['mem_kb'], reverse=True)[:20]
    
    print(f"  {'Process Name':<35} {'PID':<8} {'Memory':<12}")
    print(f"  {'-'*35} {'-'*8} {'-'*12}")
    
    for proc in processes_sorted:
        mem_str = f"{proc['mem_kb']:,} K".replace(',', ' ')
        print(f"  {proc['name'][:35]:<35} {proc['pid']:<8} {mem_str:<12}")
    
    print()
    print("=" * 44)
    print("[TIP] Use --name=process.exe to kill")
    print("=" * 44)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
