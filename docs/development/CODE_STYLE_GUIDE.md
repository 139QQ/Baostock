# 基速基金量化分析平台 - 代码风格指南

## 📋 概述

本指南定义了基速基金量化分析平台的代码风格标准，确保团队代码的一致性、可读性和可维护性。所有团队成员必须遵循这些标准进行开发。

## 🎯 目标

- **一致性**: 统一的代码风格减少认知负担
- **可读性**: 清晰的代码结构便于理解和维护
- **自动化**: 最大化利用工具自动检查和修复
- **团队协作**: 减少代码审查中的风格争议

## 📏 核心标准

### 1. 格式规范

#### 1.1 缩进和空格
```dart
// ✅ 正确 - 2个空格缩进
class FundCalculator {
  double calculateReturn(double principal, double rate) {
    final result = principal * (1 + rate);
    return result;
  }
}

// ❌ 错误 - 使用Tab或不一致的缩进
class FundCalculator {
    double calculateReturn(double principal, double rate) {
        final result=principal*(1+rate);
        return result;
    }
}
```

#### 1.2 行长度限制
```dart
// ✅ 正确 - 80字符限制，适当换行
final calculatedAnnualReturn = calculateAnnualizedReturn(
  cumulativeReturn: totalReturn,
  years: investmentPeriod,
  includeFees: true,
);

// ❌ 错误 - 超长行
final calculatedAnnualReturn = calculateAnnualizedReturn(cumulativeReturn: totalReturn, years: investmentPeriod, includeFees: true);
```

#### 1.3 操作符周围空格
```dart
// ✅ 正确 - 操作符两侧有空格
final returnRate = (currentValue - initialValue) / initialValue;
final isValid = returnRate > 0 && returnRate < 1.0;

// ❌ 错误 - 缺少空格
final returnRate=(currentValue-initialValue)/initialValue;
final isValid=returnRate>0&&returnRate<1.0;
```

### 2. 命名规范

#### 2.1 类名 - PascalCase
```dart
// ✅ 正确
class FundDetailPage
class PortfolioAnalyzer
class MarketDataProvider

// ❌ 错误
class fundDetailPage
class Portfolio_Analyzer
class marketDataProvider
```

#### 2.2 变量名 - camelCase
```dart
// ✅ 正确
final fundName = '中欧医疗健康混合';
final currentNav = 2.3456;
final isActive = true;

// ❌ 错误
final FundName = '中欧医疗健康混合';
final current_nav = 2.3456;
final is_active = true;
```

#### 2.3 常量名 - lower_snake_case
```dart
// ✅ 正确
const max_fund_count = 100;
const api_timeout_seconds = 30;
const default_page_size = 20;

// ❌ 错误
const maxFundCount = 100;
const API_TIMEOUT = 30;
const DefaultPageSize = 20;
```

#### 2.4 私有成员 - 下划线前缀
```dart
// ✅ 正确
class FundRepository {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;

  Future<List<Fund>> _fetchFromCache() async {
    // 实现代码
  }
}

// ❌ 错误
class FundRepository {
  final ApiClient apiClient; // 应该是私有的
  final CacheManager cacheManager; // 应该是私有的
}
```

### 3. 导入规范

#### 3.1 导入排序
```dart
// ✅ 正确 - dart导入 → package导入 → 相对导入
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants.dart';
import '../core/utils/logger.dart';
import 'fund_model.dart';

// ❌ 错误 - 无序导入
import 'fund_model.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';
import 'dart:async';
```

#### 3.2 导入格式
```dart
// ✅ 正确 - 每行一个导入
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ❌ 错误 - 多行导入
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; import 'package:equatable/equatable.dart';
```

### 4. 构造函数规范

#### 4.1 参数格式
```dart
// ✅ 正确 - 尾随逗号使用
class FundCard extends StatelessWidget {
  const FundCard({
    Key? key,
    required this.fund,
    this.onTap,
    this.showPerformance = true,
  }) : super(key: key);

  final Fund fund;
  final VoidCallback? onTap;
  final bool showPerformance;
}

// ❌ 错误 - 缺少尾随逗号
class FundCard extends StatelessWidget {
  const FundCard({Key? key, required this.fund, this.onTap, this.showPerformance = true}) : super(key: key);

  final Fund fund;
  final VoidCallback? onTap;
  final bool showPerformance;
}
```

#### 4.2 Widget参数顺序
```dart
// ✅ 正确 - key, child, children顺序
Widget build(BuildContext context) {
  return Container(
    key: widgetKey,
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildContent(),
      ],
    ),
  );
}
```

### 5. 注释规范

#### 5.1 文档注释
```dart
/// 计算基金的年化收益率
///
/// 该计算方法假设收益按复利计算，考虑了时间价值。
/// 用于比较不同期限基金的投资表现。
///
/// [totalReturn] 总收益率 (如: 0.25 表示25%)
/// [years] 投资年限
///
/// 返回年化收益率，如果年限为0则返回0
///
/// 示例:
/// ```dart
/// final annualized = calculateAnnualizedReturn(0.5, 2); // 返回 0.225
/// ```
double calculateAnnualizedReturn(double totalReturn, double years) {
  if (years == 0) return 0;
  return Math.pow(1 + totalReturn, 1 / years) - 1;
}
```

#### 5.2 TODO注释
```dart
// TODO(username): 2025-09-28 - 需要添加对货币基金的特殊处理逻辑
// 当前实现仅适用于股票型和混合型基金
if (fund.type == FundType.moneyMarket) {
  return calculateMoneyMarketReturn(fund);
}
```

#### 5.3 实现注释
```dart
// ✅ 有价值的注释 - 解释为什么
// 由于API返回的数据格式不统一，需要特殊处理负值情况
if (returnValue.startsWith('(') && returnValue.endsWith(')')) {
  // 移除括号并添加负号
  returnValue = '-' + returnValue.substring(1, returnValue.length - 1);
}

// ❌ 无价值的注释 - 显而易见
// 增加计数器
counter++; // 显而易见的操作不需要注释
```

## 🛠️ 工具配置

### VS Code 设置
项目已配置 `.vscode/settings.json`：

```json
{
  "dart.lineLength": 80,
  "dart.enableSdkFormatter": true,
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.rulers": [80],
  "editor.tabSize": 2,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true
  }
}
```

### Android Studio / IntelliJ
1. 打开 Preferences → Editor → Code Style → Dart
2. 设置 Line length: 80
3. 启用 "Format on save"
4. 导入项目代码风格配置

### Git Hooks
项目已配置自动化的Git钩子：

#### Pre-commit Hook
```bash
#!/bin/sh
# 运行代码格式检查
dart format --output=none --set-exit-if-changed lib/ test/

# 运行基础静态分析
flutter analyze --no-fatal-infos
```

#### Pre-push Hook
```bash
#!/bin/sh
# 运行完整格式验证
dart format --output=none --set-exit-if-changed lib/ test/

# 运行完整静态分析
flutter analyze

# 运行测试
flutter test
```

## 🔍 代码检查工具

### Dart Analysis
```bash
# 运行完整的代码分析
flutter analyze

# 仅检查严重问题
flutter analyze --no-fatal-infos

# 检查特定文件
flutter analyze lib/src/features/fund/
```

### Dart Format
```bash
# 检查格式问题（不修改文件）
dart format --output=none --set-exit-if-changed lib/

# 自动修复格式问题
dart format lib/

# 检查并显示会修改的文件
dart format --output=show --set-exit-if-changed lib/
```

### Dart Fix
```bash
# 查看可自动修复的问题
dart fix --dry-run

# 应用所有自动修复
dart fix --apply

# 修复特定类型的问题
dart fix --apply --code=unnecessary_brace_in_string_interps
```

## 📋 代码审查检查清单

### 格式检查
- [ ] 代码通过了 `dart format` 验证
- [ ] 没有超过80字符的行
- [ ] 缩进统一为2个空格
- [ ] 操作符两侧有空格

### 命名检查
- [ ] 类名使用 PascalCase
- [ ] 变量名使用 camelCase
- [ ] 常量名使用 lower_snake_case
- [ ] 私有成员有下划线前缀

### 结构检查
- [ ] 导入语句正确排序
- [ ] 构造函数使用了尾随逗号
- [ ] Widget参数按正确顺序排列
- [ ] 注释格式正确且有意义

### 质量检查
- [ ] 没有生产环境print语句
- [ ] 没有未使用的导入
- [ ] 没有未使用的变量/方法
- [ ] 公共API有完整的文档注释

## 🚀 自动化脚本

### 快速修复脚本
```bash
#!/bin/bash
# 一键修复常见代码风格问题

echo "🚀 Running code style fixes..."

# 1. 自动格式化
echo "📋 Formatting code..."
dart format lib/ test/

# 2. 自动修复常见问题
echo "🔧 Applying automatic fixes..."
dart fix --apply

# 3. 组织导入
echo "📦 Organizing imports..."
find lib/ test/ -name "*.dart" -exec dart format --fix-imports {} \;

# 4. 运行最终检查
echo "🔍 Running final checks..."
flutter analyze --no-fatal-infos

echo "✅ Code style fixes complete!"
```

### 预提交检查
```bash
#!/bin/bash
# 提交前的完整代码风格检查

set -e  # 遇到错误立即退出

echo "🔍 Running pre-commit code style validation..."

# 1. 格式检查
echo "📋 Checking code formatting..."
dart format --output=none --set-exit-if-changed lib/ test/

# 2. 静态分析
echo "🔍 Running static analysis..."
flutter analyze --no-fatal-infos

# 3. 测试运行
echo "🧪 Running tests..."
flutter test

echo "✅ All code style checks passed!"
```

## 🎓 最佳实践

### 1. 渐进式改进
- 不要试图一次性修复所有问题
- 优先修复编译错误和严重警告
- 逐步改进代码质量

### 2. 团队一致性
- 所有团队成员遵循相同标准
- 代码审查重点关注逻辑而非风格
- 定期回顾和更新标准

### 3. 自动化优先
- 最大化使用工具自动检查和修复
- 在CI/CD流程中集成代码质量检查
- 减少人工审查中的风格争议

### 4. 持续改进
- 定期运行代码质量分析
- 根据项目发展调整标准
- 收集团队反馈优化流程

## 📚 参考资源

- [Dart 官方风格指南](https://dart.dev/guides/language/effective-dart/style)
- [Flutter 代码示例](https://flutter.dev/docs/development/data-and-backend/json)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Linter Rules](https://dart-lang.github.io/linter/lints/)

---

**维护者**: 开发团队
**最后更新**: 2025-09-28
**审核状态**: 活跃维护
**关联文档**: [编码规范](../architecture/coding-standards.md), [项目结构](../architecture/source-tree.md)

## 🔄 版本历史

| 版本 | 日期 | 更新内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2025-09-28 | 初始版本创建，包含完整风格标准 | James (开发工程师) |
| v1.1 | 2025-09-28 | 添加VS Code配置和Git钩子设置 | James (开发工程师) |
| v1.2 | 2025-09-28 | 完善自动化脚本和最佳实践 | James (开发工程师) |