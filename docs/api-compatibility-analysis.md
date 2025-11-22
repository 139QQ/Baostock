# API兼容性分析报告

**文档创建日期**: 2025-11-07
**分析范围**: 基金数据API与fund_public.md规范的对比
**分析目的**: 确保所有API调用符合实际AKShare接口规范

---

## 📊 核心发现总结

### ✅ 当前兼容的API接口

| API接口 | 当前实现 | AKShare规范 | 兼容状态 |
|---------|----------|-------------|----------|
| 基金基本信息 | `fund_name_em` | `fund_name_em` | ✅ 完全兼容 |
| 基金排行榜 | `fund_open_fund_rank_em` | `fund_open_fund_rank_em` | ✅ 完全兼容 |
| 基金净值走势 | `fund_open_fund_info_em` | `fund_open_fund_info_em` | ✅ 完全兼容 |

### ❌ 缺失的准实时API接口

| API接口 | AKShare规范 | 用途 | 优先级 |
|---------|-------------|------|--------|
| `fund_etf_spot_em` | ETF基金实时行情-东财 | 获取ETF实时价格和净值 | 🔴 高 |
| `fund_etf_spot_ths` | ETF基金实时行情-同花顺 | 获取ETF实时净值数据 | 🟡 中 |
| `fund_lof_spot_em` | LOF基金实时行情-东财 | 获取LOF实时交易数据 | 🟡 中 |
| `fund_value_estimation_em` | 基金净值估算 | 实时净值估算数据 | 🔴 高 |

---

## 🔍 详细API规范分析

### 1. 基金基本信息接口

**AKShare规范**:
```python
fund_name_em_df = ak.fund_name_em()
```

**当前实现**:
```dart
static Future<Map<String, dynamic>> searchFunds(String keyword, {int limit = 20}) async {
  const endpoint = '/api/public/fund_name_em';
  return await get(endpoint);
}
```

**分析**: ✅ **兼容良好**
- 接口路径正确
- 参数传递正确
- 返回格式匹配

### 2. 基金排行榜接口

**AKShare规范**:
```python
# 输入参数: symbol (str) - 基金类型，默认"全部"
# 可选值: "全部", "股票型", "混合型", "债券型", "指数型", "QDII", "FOF"
fund_open_fund_rank_em_df = ak.fund_open_fund_rank_em(symbol="混合型")
```

**当前实现**:
```dart
static Future<Map<String, dynamic>> getFundRanking({String symbol = "全部"}) async {
  final endpoint = '/api/public/fund_open_fund_rank_em?symbol=$symbol';
  return await get(endpoint);
}
```

**分析**: ✅ **兼容良好**
- 参数名称正确: `symbol`
- 参数值符合规范: "全部", "股票型", "混合型", "债券型", "指数型", "QDII", "FOF"
- 接口路径正确

### 3. 基金净值走势接口

**AKShare规范**:
```python
# 输入参数
# symbol: 基金代码 (str)
# indicator: 指标类型 (str) - "单位净值走势" 或 "累计净值走势"
fund_open_fund_info_em_df = ak.fund_open_fund_info_em(symbol="710001", indicator="单位净值走势")
```

**当前实现**:
```dart
static Future<Map<String, dynamic>> getFundInfo(String fundCode) async {
  final endpoint = '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';
  return await get(endpoint);
}

static Future<Map<String, dynamic>> getFundAccumulatedNavHistory(String fundCode) async {
  final endpoint = '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=累计净值走势';
  return await get(endpoint);
}
```

**分析**: ✅ **兼容良好**
- 参数名称正确: `symbol`, `indicator`
- 参数值符合规范: "单位净值走势", "累计净值走势"
- 接口路径正确

---

## 🚨 关键缺失：准实时数据API

### 需要新增的API接口

#### 1. ETF实时行情接口 (优先级: 🔴 高)

**AKShare规范**:
```python
# ETF基金实时行情-东财
fund_etf_spot_em_df = ak.fund_etf_spot_em()
```

**对应实现需求**:
```dart
// 需要在FundApiClient中新增
static Future<Map<String, dynamic>> getEtfSpotData() async {
  const endpoint = '/api/public/fund_etf_spot_em';
  return await get(endpoint);
}
```

**返回数据字段**:
- 代码, 名称, 最新价, 涨跌幅, 成交量, 成交额
- IOPV实时估值, 前收盘价, 今开盘, 最高价, 最低价

#### 2. 基金净值估算接口 (优先级: 🔴 高)

**AKShare规范**:
```python
# 净值估算
fund_value_estimation_em_df = ak.fund_value_estimation_em(symbol="混合型")
```

**参数规范**:
- `symbol`: str - 基金类型
- 可选值: "全部", "股票型", "混合型", "债券型", "指数型", "QDII", "ETF联接", "LOF", "场内交易基金"

**对应实现需求**:
```dart
// 需要在FundApiClient中新增
static Future<Map<String, dynamic>> getFundValueEstimation({String symbol = "全部"}) async {
  final endpoint = '/api/public/fund_value_estimation_em?symbol=$symbol';
  return await get(endpoint);
}
```

#### 3. LOF实时行情接口 (优先级: 🟡 中)

**AKShare规范**:
```python
# LOF基金实时行情-东财
fund_lof_spot_em_df = ak.fund_lof_spot_em()
```

**对应实现需求**:
```dart
// 需要在FundApiClient中新增
static Future<Map<String, dynamic>> getLofSpotData() async {
  const endpoint = '/api/public/fund_lof_spot_em';
  return await get(endpoint);
}
```

---

## 📋 代码修改建议

### 1. FundApiClient 增强方案

需要在 `lib/src/core/network/fund_api_client.dart` 中新增以下方法：

```dart
/// 获取ETF实时行情数据 (准实时)
static Future<Map<String, dynamic>> getEtfSpotData() async {
  try {
    const endpoint = '/api/public/fund_etf_spot_em';
    return await get(endpoint);
  } catch (e) {
    AppLogger.error('获取ETF实时行情失败', e);
    rethrow;
  }
}

/// 获取LOF实时行情数据 (准实时)
static Future<Map<String, dynamic>> getLofSpotData() async {
  try {
    const endpoint = '/api/public/fund_lof_spot_em';
    return await get(endpoint);
  } catch (e) {
    AppLogger.error('获取LOF实时行情失败', e);
    rethrow;
  }
}

/// 获取基金净值估算数据 (准实时)
static Future<Map<String, dynamic>> getFundValueEstimation({String symbol = "全部"}) async {
  try {
    final endpoint = '/api/public/fund_value_estimation_em?symbol=$symbol';
    return await get(endpoint);
  } catch (e) {
    AppLogger.error('获取基金净值估算失败', e);
    rethrow;
  }
}
```

### 2. 数据模型扩展

需要为新的API响应创建对应的数据模型：

```dart
// ETF实时数据模型
class EtfSpotData {
  final String code;
  final String name;
  final double latestPrice;
  final double changePercent;
  final double volume;
  final double turnover;
  final double iopv; // 实时估值
  // ... 其他字段
}

// 净值估算数据模型
class FundValueEstimation {
  final String fundCode;
  final String fundName;
  final String estimatedValue;
  final String estimationDeviation;
  final String latestNav;
  // ... 其他字段
}
```

### 3. Epic 2 准实时数据服务

基于新的API接口，实现Epic 2中定义的准实时数据轮询服务：

```dart
class QuasiRealtimeDataService {
  final FundApiClient _apiClient;
  final Timer _pollingTimer;

  Future<void> startRealtimePolling() async {
    // 使用 getEtfSpotData(), getFundValueEstimation() 等新接口
    // 实现轮询逻辑
  }
}
```

---

## 🎯 实施优先级

### 第一阶段 (高优先级)
1. ✅ 分析现有API兼容性 - 已完成
2. 🔲 实现 `getEtfSpotData()` 接口
3. 🔲 实现 `getFundValueEstimation()` 接口
4. 🔲 创建对应数据模型

### 第二阶段 (中优先级)
1. 🔲 实现 `getLofSpotData()` 接口
2. 🔲 集成到Epic 2准实时数据服务
3. 🔲 更新相关业务逻辑

### 第三阶段 (低优先级)
1. 🔲 性能优化和缓存策略
2. 🔲 错误处理和降级机制
3. 🔲 单元测试和集成测试

---

## 📝 总结

1. **现有API兼容性**: 当前实现的3个核心API接口与AKShare规范完全兼容
2. **关键缺失**: 缺少准实时数据相关的4个重要API接口
3. **实施建议**: 优先实现ETF实时行情和净值估算接口，为Epic 2提供数据基础
4. **代码质量**: 现有代码结构良好，新增接口可无缝集成

所有后续的API调用开发都应严格参考 `docs/api/fund_public.md` 规范，确保参数名称、参数值、接口路径完全匹配。