@echo off
echo 正在修复Android资源配置...

REM 创建默认应用图标资源
echo 创建应用图标资源...

REM 创建简单的XML图标资源
echo ^<?xml version="1.0" encoding="utf-8"?^> > android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo ^<vector xmlns:android="http://schemas.android.com/apk/res/android"^> >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo     android:width="108dp" >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo     android:height="108dp" >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo     android:viewportWidth="108" >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo     android:viewportHeight="108"^> >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo     ^<path >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo         android:fillColor="#3DDC84" >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo         android:pathData="M0,0h108v108h-108z"/^> >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml
echo ^</vector^> >> android\app\src\main\res\mipmap-hdpi\ic_launcher.xml

REM 复制到其他分辨率目录
copy android\app\src\main\res\mipmap-hdpi\ic_launcher.xml android\app\src\main\res\mipmap-mdpi\ic_launcher.xml
copy android\app\src\main\res\mipmap-hdpi\ic_launcher.xml android\app\src\main\res\mipmap-xhdpi\ic_launcher.xml
copy android\app\src\main\res\mipmap-hdpi\ic_launcher.xml android\app\src\main\res\mipmap-xxhdpi\ic_launcher.xml
copy android\app\src\main\res\mipmap-hdpi\ic_launcher.xml android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.xml

echo Android资源配置修复完成！
echo 现在可以运行: flutter run

pause