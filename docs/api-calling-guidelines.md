# API调用规范指南

**文档版本**: v1.0
**创建日期**: 2025-11-07
**适用范围**: 基速基金量化分析平台所有API调用开发

---

## 📖 核心原则

1. **严格遵循规范**: 所有API调用必须严格参考 `docs/api/fund_public.md` 规范
2. **参数一致性**: 参数名称、类型、可选值必须与AKShare规范完全匹配
3. **路径规范性**: API端点路径必须与AKShare接口名称保持一致
4. **错误处理**: 所有API调用必须包含适当的错误处理和日志记录

---

## 🔧 API调用检查清单

### ✅ 调用前检查

- [ ] 已查阅 `docs/api/fund_public.md` 中的接口规范
- [ ] 确认参数名称拼写正确
- [ ] 确认参数可选值符合规范要求
- [ ] 确认API端点路径正确
- [ ] 已添加参考注释指向具体规范文档

### ✅ 代码实现检查

- [ ] 使用正确的参数名称
- [ ] 参数值符合AKShare规范的可选值
- [ ] 错误处理包含详细的错误信息
- [ ] 日志记录包含足够的调试信息
- [ ] 方法注释引用对应的AKShare接口

### ✅ 测试验证检查

- [ ] API调用成功返回数据
- [ ] 参数验证正确工作
- [ ] 错误场景被正确处理
- [ ] 返回数据格式与预期一致

---

## 📋 标准API调用模板

### 基础模板

```dart
/// 获取[数据描述]
/// 参考：docs/api/fund_public.md 中的 [AKShare接口名称] 接口规范
static Future<Map<String, dynamic>> get[DataName]({
  // 参数列表，包含可选值说明
  [ParameterType] [parameterName] = [defaultValue], // 可选值: [values]
}) async {
  try {
    final endpoint = '/api/public/[akshare_interface_name]?[parameter_name]=$[parameter_name]';
    return await get(endpoint);
  } catch (e) {
    AppLogger.error('获取[数据描述]失败', e);
    rethrow;
  }
}
```

### 复杂参数模板

```dart
/// 获取[数据描述]
/// 参考：docs/api/fund_public.md 中的 [AKShare接口名称] 接口规范
static Future<Map<String, dynamic>> get[DataName]({
  // 必需参数
  required String symbol, // 基金代码
  // 可选参数
  String indicator = "默认值", // 可选值: "值1", "值2", "值3"
  String period = "默认值",   // 可选值: "值1", "值2", "值3"
}) async {
  try {
    final endpoint = '/api/public/[akshare_interface_name]?'
                    'symbol=$symbol'
                    '&indicator=$indicator'
                    '&period=$period';
    return await get(endpoint);
  } catch (e) {
    AppLogger.error('获取[数据描述]失败', e);
    rethrow;
  }
}
```

---

## 📊 已验证的API接口

### ✅ 完全兼容接口

| 接口名称 | AKShare规范 | 当前实现 | 状态 |
|---------|-------------|----------|------|
| `fund_name_em` | ✅ 无参数 | `searchFunds()` | ✅ 验证通过 |
| `fund_open_fund_rank_em` | ✅ symbol参数 | `getFundRanking()` | ✅ 验证通过 |
| `fund_open_fund_info_em` | ✅ symbol + indicator | `getFundInfo()` | ✅ 验证通过 |
| `fund_value_estimation_em` | ✅ symbol参数 | `getFundValueEstimation()` | ✅ 验证通过 |

### 🆕 新增准实时接口

| 接口名称 | AKShare规范 | 新增实现 | 状态 |
|---------|-------------|----------|------|
| `fund_etf_spot_em` | ✅ 无参数 | `getEtfSpotData()` | ✅ 已添加 |
| `fund_etf_spot_ths` | ✅ 可选date参数 | `getEtfSpotDataThs()` | ✅ 已添加 |
| `fund_lof_spot_em` | ✅ 无参数 | `getLofSpotData()` | ✅ 已添加 |
| `fund_etf_fund_daily_em` | ✅ 无参数 | `getTradingFundsDaily()` | ✅ 已添加 |

---

## 🚨 常见错误及解决方案

### 错误1: 参数名称拼写错误

```dart
// ❌ 错误示例
final endpoint = '/api/public/fund_etf_spot_em?symbol=$symbol'; // 参数名错误

// ✅ 正确示例
final endpoint = '/api/public/fund_etf_spot_em'; // 无参数接口
```

### 错误2: 参数可选值不匹配

```dart
// ❌ 错误示例
getFundRanking(symbol: "所有"); // 可选值错误

// ✅ 正确示例
getFundRanking(symbol: "全部"); // 使用规范中的正确可选值
```

### 错误3: 缺少规范引用

```dart
// ❌ 错误示例
/// 获取ETF实时数据
static Future<Map<String, dynamic>> getEtfData() async { ... }

// ✅ 正确示例
/// 获取ETF实时行情数据 - 东方财富
/// 参考：docs/api/fund_public.md 中的 fund_etf_spot_em 接口规范
static Future<Map<String, dynamic>> getEtfSpotData() async { ... }
```

---

## 📝 新API开发流程

### 1. 规范研究
1. 查阅 `docs/api/fund_public.md`
2. 确认接口名称、参数、返回字段
3. 验证参数可选值范围

### 2. 代码实现
1. 使用标准模板创建方法
2. 添加规范引用注释
3. 实现完整的错误处理

### 3. 测试验证
1. 测试正常调用场景
2. 测试参数验证
3. 测试错误处理

### 4. 文档更新
1. 更新本文档中的接口列表
2. 添加新接口的使用示例
3. 更新API兼容性分析报告

---

## 🔍 规范对照表

### 基金类型参数规范

| 当前使用值 | AKShare规范值 | 兼容性 | 说明 |
|-----------|---------------|--------|------|
| "全部" | "全部" | ✅ | 默认值 |
| "股票型" | "股票型" | ✅ | - |
| "混合型" | "混合型" | ✅ | - |
| "债券型" | "债券型" | ✅ | - |
| "指数型" | "指数型" | ✅ | - |
| "QDII" | "QDII" | ✅ | - |
| "FOF" | "FOF" | ✅ | - |

### 净值指标参数规范

| 当前使用值 | AKShare规范值 | 兼容性 | 说明 |
|-----------|---------------|--------|------|
| "单位净值走势" | "单位净值走势" | ✅ | 单位净值历史 |
| "累计净值走势" | "累计净值走势" | ✅ | 累计净值历史 |
| "累计收益率走势" | "累计收益率走势" | ✅ | 收益率历史 |

### 基金分类参数规范

| 当前使用值 | AKShare规范值 | 兼容性 | 说明 |
|-----------|---------------|--------|------|
| "封闭式基金" | "封闭式基金" | ✅ | - |
| "ETF基金" | "ETF基金" | ✅ | - |
| "LOF基金" | "LOF基金" | ✅ | - |

---

## 📞 技术支持

如果在API调用开发过程中遇到问题：

1. **首先检查**: `docs/api/fund_public.md` 中的最新规范
2. **参考文档**: `docs/api-compatibility-analysis.md` 兼容性分析
3. **查看示例**: 本文档中的标准模板和正确示例
4. **代码审查**: 确保遵循所有检查清单项目

---

## 📈 版本历史

- **v1.0** (2025-11-07): 初始版本，包含基础API调用规范和Epic 2准实时接口
  - 添加4个准实时数据API接口
  - 完善现有API的规范引用
  - 创建API调用检查清单和模板