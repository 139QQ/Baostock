@echo off
REM 环境配置设置脚本 (Windows版本)
REM 用于快速设置开发环境配置

echo 🔧 基金分析平台环境配置设置脚本
echo ==================================

REM 检查是否存在.env文件
if exist ".env" (
    echo ⚠️  .env文件已存在，将备份当前配置
    copy .env .env.backup.%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
)

REM 设置环境类型
set ENV_TYPE=%1
if "%ENV_TYPE%"=="" set ENV_TYPE=development

echo 📋 设置环境类型: %ENV_TYPE%

REM 根据环境类型复制配置文件
if "%ENV_TYPE%"=="development" goto :development
if "%ENV_TYPE%"=="dev" goto :development
if "%ENV_TYPE%"=="production" goto :production
if "%ENV_TYPE%"=="prod" goto :production

echo ❌ 不支持的环境类型: %ENV_TYPE%
echo 支持的环境类型: development, production
exit /b 1

:development
if exist ".env.development" (
    echo ✅ 使用开发环境配置
    copy .env.development .env
    echo FLUTTER_ENV=development >> .env
    goto :success
) else (
    echo ❌ 开发环境配置文件不存在
    exit /b 1
)

:production
if exist ".env.production" (
    echo ✅ 使用生产环境配置
    copy .env.production .env
    echo FLUTTER_ENV=production >> .env
    goto :success
) else (
    echo ❌ 生产环境配置文件不存在
    exit /b 1
)

:success
echo ✅ 环境配置设置完成
echo.
echo 📝 当前配置摘要:
findstr "API_BASE_URL DB_HOST DB_PORT DB_DATABASE" .env
echo.
echo 🚀 下一步操作:
echo    flutter pub get
echo    flutter run -d windows
echo.
echo ⚠️  注意事项:
echo    - 请确保配置文件中的凭据正确
echo    - 生产环境请使用安全的密码
echo    - .env文件已添加到.gitignore，不会被提交
pause