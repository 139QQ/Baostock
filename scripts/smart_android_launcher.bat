@echo off
echo 🚀 智能Android启动器 v1.0
echo ==================================

echo 📱 检查Android模拟器状态...
flutter emulators

echo.
echo 🔍 检查可用设备...
flutter devices

echo.
echo 🚀 启动Pixel 7模拟器...
start "Android Emulator" /min flutter emulators --launch Pixel_7_API_30

echo ⏳ 等待模拟器启动 (30秒)...
timeout /t 30 /nobreak >nul

echo 📊 再次检查设备状态...
flutter devices

echo.
echo 🎯 准备启动Flutter应用...
echo.
echo 💡 使用方法:
echo   1. 等待模拟器完全启动
echo   2. 在VS Code中按F5运行应用
echo   3. 或使用命令: flutter run
echo.

echo 📝 当前可用命令:
echo   flutter devices     - 查看设备
echo   flutter run         - 运行应用
echo   flutter emulators   - 查看模拟器列表
echo.

pause