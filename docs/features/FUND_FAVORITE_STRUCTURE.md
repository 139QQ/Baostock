# 自选基金完整信息结构

## 📋 概述

自选基金实体包含完整的基金信息，涵盖基础信息、实时行情数据、用户配置和系统管理信息。

## 🏗️ 核心信息结构

### 1. 基础信息 (必填)
| 字段名 | 数据类型 | 描述 | 示例 | 来源 |
|--------|----------|------|------|------|
| `fundCode` | `String` | 基金代码 | "000001" | 用户输入 |
| `fundName` | `String` | 基金全称 | "华夏成长混合" | API获取 |
| `fundType` | `String` | 基金类型 | "混合型" | API获取 |
| `fundManager` | `String` | 基金管理人 | "华夏基金管理有限公司" | API获取 |

### 2. 实时行情数据 (API获取)
| 字段名 | 数据类型 | 描述 | 示例 | API端点 |
|--------|----------|------|------|----------|
| `currentNav` | `double?` | 当前净值 | 2.3456 | fund_open_fund_info_em |
| `dailyChange` | `double?` | 日涨跌幅(%) | 1.23 | fund_open_fund_info_em |
| `previousNav` | `double?` | 前一日净值 | 2.3185 | fund_open_fund_info_em |
| `fundScale` | `double?` | 基金规模(亿元) | 128.5 | fund_open_fund_info_em |

### 3. 基金详情 (API获取)
| 字段名 | 数据类型 | 描述 | 示例 | API端点 |
|--------|----------|------|------|----------|
| `establishDate` | `DateTime?` | 基金成立日期 | "2001-12-18" | fund_open_fund_info_em |
| `riskLevel` | `String?` | 风险等级 | "中风险" | fund_open_fund_info_em |
| `managementFee` | `double?` | 管理费率(%) | 1.5 | fund_open_fund_info_em |
| `custodyFee` | `double?` | 托管费率(%) | 0.25 | fund_open_fund_info_em |
| `performanceFee` | `double?` | 业绩报酬(%) | 0 | fund_open_fund_info_em |

### 4. 用户配置
| 字段名 | 数据类型 | 描述 | 示例 |
|--------|----------|------|------|
| `notes` | `String?` | 用户备注 | "长期持有的优质基金" |
| `priceAlerts` | `PriceAlertSettings?` | 价格提醒设置 | 见下方结构 |
| `sortWeight` | `double` | 自定义排序权重 | 0.0 |

### 5. 系统管理信息
| 字段名 | 数据类型 | 描述 | 示例 |
|--------|----------|------|------|
| `addedAt` | `DateTime` | 添加到自选的时间 | "2025-10-22T10:30:00Z" |
| `updatedAt` | `DateTime` | 最后更新时间 | "2025-10-22T15:00:00Z" |
| `isSynced` | `bool` | 是否同步到云端 | false |
| `cloudId` | `String?` | 云端同步ID | "cloud_123456" |

## 🔔 价格提醒设置结构

### PriceAlertSettings
```dart
class PriceAlertSettings {
  final bool enabled;                    // 是否启用提醒
  final double? riseThreshold;          // 上涨阈值(%)
  final double? fallThreshold;          // 下跌阈值(%)
  final List<TargetPriceAlert> targetPrices;  // 目标价格列表
  final DateTime? lastAlertTime;         // 最后提醒时间
  final List<AlertMethod> alertMethods; // 提醒方式
}
```

### TargetPriceAlert
```dart
class TargetPriceAlert {
  final double targetPrice;    // 目标价格
  final TargetPriceType type;  // 提醒类型
  final bool isActive;         // 是否激活
  final DateTime createdAt;    // 创建时间
}
```

## 📡 API数据源详情

### 主要API端点
```
http://154.44.25.92:8080/api/public/fund_open_fund_info_em?symbol={基金代码}
```

### 预期API响应结构
```json
{
  "基金代码": "000001",
  "基金名称": "华夏成长混合",
  "基金类型": "混合型",
  "基金管理人": "华夏基金管理有限公司",
  "成立日期": "2001-12-18",
  "最新净值": "2.3456",
  "日涨跌幅": "1.23",
  "前日净值": "2.3185",
  "基金规模": "128.5",
  "风险等级": "中风险",
  "管理费": "1.5",
  "托管费": "0.25",
  "业绩报酬": "0",
  "更新时间": "2025-10-22 15:00:00"
}
```

## 🔄 数据同步流程

### 1. 初始添加流程
```
用户输入基金代码 → 验证格式 → 创建基础记录 → API获取完整信息 → 更新本地数据
```

### 2. 实时更新流程
```
定时任务 → 调用API → 更新净值数据 → 检查价格提醒 → 通知用户
```

### 3. 数据缓存策略
- **净值数据**: 缓存15分钟
- **基础信息**: 缓存24小时
- **历史数据**: 按需缓存，定期清理

## 📱 完整示例

### 完整的FundFavorite对象
```dart
FundFavorite(
  fundCode: "000001",
  fundName: "华夏成长混合",
  fundType: "混合型",
  fundManager: "华夏基金管理有限公司",
  addedAt: DateTime.parse("2025-10-22T10:30:00Z"),
  sortWeight: 0.0,
  notes: "优质成长基金，适合长期持有",
  priceAlerts: PriceAlertSettings(
    enabled: true,
    riseThreshold: 5.0,
    fallThreshold: -3.0,
    targetPrices: [
      TargetPriceAlert(
        targetPrice: 3.0,
        type: TargetPriceType.exceed,
        createdAt: DateTime.parse("2025-10-22T10:30:00Z"),
      ),
    ],
    alertMethods: [AlertMethod.push],
  ),
  updatedAt: DateTime.parse("2025-10-22T15:00:00Z"),
  currentNav: 2.3456,
  dailyChange: 1.23,
  previousNav: 2.3185,
  establishDate: DateTime.parse("2001-12-18"),
  fundScale: 128.5,
  isSynced: false,
  cloudId: null,
)
```

## 🎯 必要信息 vs 可选信息

### 必要信息 (核心功能)
- ✅ **基金代码**: 唯一标识
- ✅ **基金名称**: 显示用
- ✅ **基金类型**: 分类筛选
- ✅ **当前净值**: 收益计算
- ✅ **添加时间**: 排序用

### 重要信息 (增强功能)
- ✅ **日涨跌幅**: 收益展示
- ✅ **基金管理人**: 信息参考
- ✅ **基金规模**: 评估参考
- ✅ **成立日期**: 历史参考

### 可选信息 (扩展功能)
- ⚪ **价格提醒**: 个性化提醒
- ⚪ **用户备注**: 个人笔记
- ⚪ **排序权重**: 自定义排序
- ⚪ **云端同步**: 多设备同步

## 📊 数据完整性检查

### 必填字段验证
```dart
bool isComplete(FundFavorite favorite) {
  return favorite.fundCode.isNotEmpty &&
         favorite.fundName.isNotEmpty &&
         favorite.fundType.isNotEmpty &&
         favorite.fundManager.isNotEmpty &&
         favorite.currentNav != null;
}
```

### 数据质量评估
```dart
double getDataQualityScore(FundFavorite favorite) {
  int totalFields = 15;  // 总字段数
  int filledFields = 0;

  if (favorite.fundCode.isNotEmpty) filledFields++;
  if (favorite.fundName.isNotEmpty) filledFields++;
  if (favorite.currentNav != null) filledFields++;
  if (favorite.dailyChange != null) filledFields++;
  // ... 其他字段检查

  return filledFields / totalFields;  // 返回0-1的完整度评分
}
```

---

**文档版本**: v1.0
**最后更新**: 2025-10-22
**API版本**: 自建API v1.0