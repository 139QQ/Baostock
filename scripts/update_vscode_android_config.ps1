# VS Code Android配置更新脚本 (PowerShell)
Write-Host "🔍 检测Flutter设备..." -ForegroundColor Green

# 获取Flutter设备列表
$devicesOutput = flutter devices
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 无法获取设备信息" -ForegroundColor Red
    exit 1
}

# 解析Android设备
$androidDevices = @()
$lines = $devicesOutput -split "`n"

foreach ($line in $lines) {
    if ($line -match "android" -and $line -match "emulator") {
        # 提取设备ID
        if ($line -match "(\w+-\d+)") {
            $deviceId = $matches[1]
            $deviceName = ($line -split "•")[0].Trim()
            $androidDevices += @{
                Id = $deviceId
                Name = $deviceName
            }
        }
    }
}

if ($androidDevices.Count -eq 0) {
    Write-Host "❌ 未找到Android设备" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到 $($androidDevices.Count) 个Android设备:" -ForegroundColor Green
foreach ($device in $androidDevices) {
    Write-Host "   - $($device.Name) ($($device.Id))" -ForegroundColor Cyan
}

# 更新launch.json
$launchFile = ".vscode/launch.json"
if (-not (Test-Path $launchFile)) {
    Write-Host "❌ 找不到 $launchFile" -ForegroundColor Red
    exit 1
}

try {
    $config = Get-Content $launchFile | ConvertFrom-Json

    # 更新Android配置
    $primaryDevice = $androidDevices[0].Id

    foreach ($configItem in $config.configurations) {
        if ($configItem.name -like "*Android*" -and $configItem.name -notlike "*Emulator*") {
            if ($configItem.name -like "*Auto*") {
                $configItem.args = @()
            } else {
                $configItem.args = @("-d", $primaryDevice)
            }
        }
        elseif ($configItem.name -eq "Flutter: Android Emulator") {
            $configItem.args = @("-d", $primaryDevice)
        }

        # 更新所有Android相关配置的设备ID
        if ($configItem.name -like "*Android*" -and $configItem.args.Count -gt 1) {
            if ($configItem.args[0] -eq "-d") {
                $configItem.args[1] = $primaryDevice
            }
        }
    }

    # 保存配置
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $launchFile -Encoding UTF8
    Write-Host "✅ VS Code Android配置已更新" -ForegroundColor Green
    Write-Host "📝 使用设备: $primaryDevice" -ForegroundColor Yellow

} catch {
    Write-Host "❌ 配置更新失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 现在可以在VS Code中使用F5启动Android调试" -ForegroundColor Green