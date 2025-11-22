# VS Code Android开发环境配置指南

## 环境要求

### 1. 安装必要软件
- **VS Code** 最新版本
- **Flutter SDK** 3.13.0+
- **Android Studio** 或 **Android SDK Command-line Tools**
- **Java JDK** 17+

### 2. VS Code插件安装
安装以下VS Code插件：
```
- Flutter
- Dart
- Android iOS Emulator
```

## 环境配置步骤

### 步骤1：配置Android SDK路径

1. 设置环境变量：
```bash
# Windows
set ANDROID_HOME=D:\AndroidSDK
set PATH=%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools;%PATH%

# 添加到系统环境变量
JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
```

2. 验证配置：
```bash
flutter doctor -v
```

### 步骤2：配置Android模拟器

1. 创建AVD：
```bash
flutter emulators --create --name Pixel_7_API_30 --system android-30-google-apis-playstore
```

2. 启动模拟器：
```bash
flutter emulators --launch Pixel_7_API_30
```

### 步骤3：项目配置

1. 确保项目包含完整的Android配置
2. 配置正确的Gradle版本
3. 设置正确的编译SDK版本

### 步骤4：VS Code配置

1. 打开VS Code设置
2. 搜索"flutter sdk path"
3. 设置Flutter SDK路径
4. 重启VS Code

## 常见问题解决

### 问题1：找不到Android设备
```bash
# 解决方案
flutter devices
flutter emulators
adb devices
```

### 问题2：Gradle构建失败
```bash
# 清理项目
flutter clean
flutter pub get

# 检查Gradle配置
cd android
./gradlew clean
```

### 问题3：Java版本问题
```bash
# 检查Java版本
java -version
# 确保使用Java 17
```

### 问题4：权限问题
```bash
# 以管理员身份运行VS Code
# 或配置模拟器权限
```

## VS Code运行步骤

1. **打开项目**：VS Code → File → Open Folder
2. **选择设备**：Ctrl+Shift+P → "Flutter: Select Device"
3. **运行项目**：F5 或 Ctrl+F5
4. **热重载**：保存文件或按F5

## 调试技巧

### 1. 使用调试器
- 在VS Code中设置断点
- 使用调试控制台
- 查看变量和调用栈

### 2. 日志查看
```bash
# 查看Flutter日志
flutter logs

# 查看Android日志
adb logcat
```

### 3. 性能分析
- 使用Flutter Inspector
- 使用Flutter Performance
- 使用Android Profiler

## 最佳实践

1. **定期更新**：保持Flutter和依赖包最新
2. **版本控制**：.gitignore包含build/目录
3. **代码规范**：使用dart format和flutter analyze
4. **测试**：编写并运行单元测试和集成测试

## 故障排除清单

- [ ] Flutter doctor显示所有项目正常
- [ ] Android SDK路径正确设置
- [ ] 模拟器可以正常启动
- [ ] 项目依赖正确安装
- [ ] Gradle配置正确
- [ ] VS Code插件正确安装
- [ ] 权限设置正确