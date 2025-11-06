#!/usr/bin/env python3
"""
动态更新VS Code Android配置脚本
自动检测Android设备并更新launch.json
"""

import json
import subprocess
import sys
import re

def get_flutter_devices():
    """获取Flutter设备列表"""
    try:
        result = subprocess.run(['flutter', 'devices'], capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        print(f"获取设备失败: {e}")
        return ""

def parse_android_devices(devices_output):
    """解析Android设备信息"""
    android_devices = []
    lines = devices_output.split('\n')

    for line in lines:
        if 'android' in line.lower() and 'emulator' in line.lower():
            # 提取设备ID (格式: emulator-5554)
            match = re.search(r'(\w+-\d+)', line)
            if match:
                device_id = match.group(1)
                # 提取设备名称
                device_name = line.split(' • ')[0].strip()
                android_devices.append({
                    'id': device_id,
                    'name': device_name
                })

    return android_devices

def update_launch_json(android_devices):
    """更新launch.json配置"""
    launch_file = '.vscode/launch.json'

    try:
        with open(launch_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"找不到 {launch_file}")
        return False

    if not android_devices:
        print("未找到Android设备，保持现有配置")
        return True

    # 更新Android相关配置
    for i, config_item in enumerate(config['configurations']):
        if 'Android' in config_item['name'] and 'Emulator' not in config_item['name']:
            # 更新第一个Android配置为自动检测
            if 'Auto' in config_item['name']:
                config_item['args'] = []
            else:
                # 使用第一个Android设备
                config_item['args'] = ['-d', android_devices[0]['id']]

        elif 'Android Emulator' in config_item['name']:
            # 使用第一个Android设备
            config_item['args'] = ['-d', android_devices[0]['id']]

        # 更新所有Android相关配置的设备ID
        if 'Android' in config_item['name'] and len(config_item['args']) > 1:
            if config_item['args'][0] == '-d':
                config_item['args'][1] = android_devices[0]['id']

    # 保存配置
    with open(launch_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=4, ensure_ascii=False)

    return True

def main():
    print("🔍 检测Flutter设备...")
    devices_output = get_flutter_devices()

    if not devices_output:
        print("❌ 无法获取设备信息")
        return

    print("📱 解析Android设备...")
    android_devices = parse_android_devices(devices_output)

    if not android_devices:
        print("❌ 未找到Android设备")
        return

    print(f"✅ 找到 {len(android_devices)} 个Android设备:")
    for device in android_devices:
        print(f"   - {device['name']} ({device['id']})")

    print("🔧 更新VS Code配置...")
    if update_launch_json(android_devices):
        print("✅ VS Code Android配置已更新")
        print(f"📝 使用设备: {android_devices[0]['id']}")
    else:
        print("❌ 配置更新失败")

if __name__ == "__main__":
    main()