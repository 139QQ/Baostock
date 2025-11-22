# Android权限配置说明

## 权限概览

基速基金分析平台Android版本已配置以下权限：

### 网络权限
```xml
<!-- 基础网络访问权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### 存储权限
```xml
<!-- 文件存储访问权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

### 设备权限
```xml
<!-- 设备功能权限 -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## 网络安全配置

### 允许HTTP连接的域名
```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">154.44.25.92</domain>
    <domain includeSubdomains="true">localhost</domain>
    <domain includeSubdomains="true">127.0.0.1</domain>
    <domain includeSubdomains="true">10.0.2.2</domain>
</domain-config>
```

### 应用级配置
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="true"
    android:requestLegacyExternalStorage="true">
```

## 权限说明

### 网络权限
- **INTERNET**: 允许应用访问网络，获取基金数据
- **ACCESS_NETWORK_STATE**: 检查网络连接状态
- **ACCESS_WIFI_STATE**: 检查WiFi连接状态

### 存储权限
- **READ_EXTERNAL_STORAGE**: 读取外部存储（如导出数据）
- **WRITE_EXTERNAL_STORAGE**: 写入外部存储（API 28及以下）

### 设备权限
- **VIBRATE**: 提供触觉反馈（用户交互）
- **WAKE_LOCK**: 保持设备唤醒（数据同步时）

## 安全考虑

### HTTP明文传输
为支持开发环境，允许以下域名的HTTP连接：
- `154.44.25.92`: 生产API服务器
- `localhost`: 本地开发服务器
- `127.0.0.1`: 本地回环地址
- `10.0.2.2`: Android模拟器桥接地址

### 存储权限限制
写入外部存储权限仅适用于API 28及以下版本，符合Android最新安全规范。

## 运行时权限处理

应用应在以下场景请求运行时权限：

### 存储权限
- 用户导出基金数据报告
- 保存图表到相册
- 导入配置文件

### 网络状态检查
- 应用启动时检查网络连接
- 数据同步前确认网络可用性

## 权限配置文件位置

- **AndroidManifest.xml**: `android/app/src/main/AndroidManifest.xml`
- **网络安全配置**: `android/app/src/main/res/xml/network_security_config.xml`

## 测试验证

### 验证网络权限
```bash
# 确保API调用正常
flutter run
# 检查网络请求日志
```

### 验证存储权限
```bash
# 测试数据导出功能
# 检查文件访问权限
```

## 常见问题

### 1. HTTP连接被阻止
- 确认`networkSecurityConfig.xml`配置正确
- 检查目标域名是否在允许列表中
- 验证`usesCleartextTraffic="true"`设置

### 2. 存储权限被拒绝
- Android 10+版本需要使用分区存储
- 考虑使用`MediaStore` API
- 检查`requestLegacyExternalStorage`设置

### 3. 网络状态检查失败
- 确认已添加`ACCESS_NETWORK_STATE`权限
- 检查ConnectivityManager使用方式
- 验证网络权限请求时机

## 更新日志

### 2025-11-04
- ✅ 添加完整的网络权限配置
- ✅ 配置HTTP明文传输支持
- ✅ 添加存储访问权限
- ✅ 配置设备功能权限
- ✅ 创建网络安全策略文件