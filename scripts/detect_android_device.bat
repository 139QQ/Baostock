@echo off
echo 检测Android设备状态...

echo.
echo === Flutter设备列表 ===
flutter devices

echo.
echo === Android模拟器列表 ===
flutter emulators

echo.
echo === ADB设备列表 ===
adb devices

echo.
echo === 网络连接测试 ===
echo 测试模拟器网络连接...
adb -s emulator-5554 shell ping -c 1 8.8.8.8 2>nul || echo 模拟器网络连接失败

echo.
echo === 建议的VS Code调试配置 ===
echo 1. Flutter: Android (Auto) - 自动选择可用设备
echo 2. Flutter: Android Emulator - 连接emulator-5554
echo 3. 使用任务: Flutter: Run Android (Smart)

pause