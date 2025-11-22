# 基金API参数修正报告

## 修正概述

根据 `docs/api/fund_public.md` 文档，对项目中使用的基金API接口进行了全面检查和修正，确保所有API调用符合官方文档规范。

## 已修正的API接口

### 1. 基金排行接口

**修正前：**
- API端点：`/api/public/fund_rank_em`
- 参数：`ranking_type`, `period`

**修正后：**
- API端点：`/api/public/fund_open_fund_rank_em`
- 参数：`symbol` (可选，默认"全部")

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`
- `lib/src/shared/widgets/charts/services/chart_data_service.dart`
- `lib/src/features/fund/data/datasources/fund_remote_data_source.dart`
- `lib/src/features/fund/presentation/domain/services/fund_pagination_service.dart`
- `lib/src/features/fund/presentation/domain/services/multi_layer_retry_service.dart`

### 2. 基金详情接口

**修正前：**
- API端点：`/api/public/fund_info_em`
- 参数：`symbol`

**修正后：**
- API端点：`/api/public/fund_open_fund_info_em`
- 参数：`symbol`, `indicator` (默认"单位净值走势")

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`

### 3. 基金历史数据接口

**修正前：**
- API端点：`/api/public/fund_history_info_em`
- 参数：`symbol`, `period`

**修正后：**
- API端点：`/api/public/fund_open_fund_info_em`
- 参数：`symbol`, `indicator` ("累计收益率走势"), `period` (默认"成立来")

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`
- `lib/src/features/portfolio/data/services/portfolio_profit_api_service.dart`

**新增辅助方法：**
```dart
String _convertToApiPeriod(String internalFormat) {
  // 将内部格式(1W, 1M, 3M等)转换为API文档格式(1月, 3月, 6月等)
}
```

### 4. 基金持仓接口

**修正前：**
- API端点：`/api/public/fund_portfolio_em`
- 参数：`symbol`

**修正后：**
- API端点：`/api/public/fund_portfolio_hold_em`
- 参数：`symbol`, `date` (可选，默认当前年份)

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`

### 5. 基金公司接口

**修正前：**
- API端点：`/api/public/fund_company_em` (不存在)
- 备注：从基金基本信息中提取

**修正后：**
- API端点：`/api/public/fund_aum_em`
- 参数：无
- 描述：基金公司规模详情

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`

### 6. 基金搜索接口

**修正前：**
- API端点：`/api/public/fund_search_em` (不存在)
- 参数：`keyword`, `limit`

**修正后：**
- API端点：`/api/public/fund_name_em`
- 参数：无
- 备注：获取所有基金列表，在客户端进行过滤

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`

### 7. 基金类型接口

**修正前：**
- API端点：`/api/public/fund_type_em` (不存在)
- 参数：无

**修正后：**
- API端点：`/api/public/fund_open_fund_rank_em?symbol=全部`
- 参数：`symbol` (支持按基金类型筛选)
- 新增多个基金类型相关方法：
  - `getFundsByType()` - 获取指定类型的基金列表
  - `getMoneyFundsDaily()` - 获取货币型基金实时数据
  - `getIndexFunds()` - 获取指数型基金信息
  - `getEtfCategory()` - 获取ETF基金分类信息
  - `getFundValueEstimation()` - 获取基金估值数据（按类型）

**支持的基金类型：**
- 基金排行：`"全部"`, `"股票型"`, `"混合型"`, `"债券型"`, `"指数型"`, `"QDII"`, `"FOF"`
- 指数型基金：`"全部"`, `"沪深指数"`, `"行业主题"`, `"大盘指数"`, `"中盘指数"`, `"小盘指数"`, `"股票指数"`, `"债券指数"`
- ETF分类：`"封闭式基金"`, `"ETF基金"`, `"LOF基金"`
- 基金估值：`'全部'`, `'股票型'`, `'混合型'`, `'债券型'`, `'指数型'`, `'QDII'`, `'ETF联接'`, `'LOF'`, `'场内交易基金'`

**影响文件：**
- `lib/src/core/network/fund_api_client.dart`

## 验证正确的API接口

以下接口在API文档中确实存在，无需修改：

✅ `fund_name_em` - 基金基本信息
✅ `fund_open_fund_rank_em` - 开放式基金排行
✅ `fund_open_fund_info_em` - 具体基金信息
✅ `fund_portfolio_hold_em` - 基金持仓
✅ `fund_portfolio_bond_hold_em` - 债券持仓
✅ `fund_portfolio_industry_allocation_em` - 行业配置
✅ `fund_portfolio_change_em` - 重大变动
✅ `fund_manager_em` - 基金经理大全
✅ `fund_aum_em` - 基金公司规模
✅ `fund_aum_hist_em` - 基金公司历年管理规模
✅ `fund_purchase_em` - 基金申购状态
✅ `fund_etf_spot_em` - ETF实时行情
✅ `fund_money_fund_daily_em` - 货币型基金实时数据
✅ `fund_money_fund_info_em` - 货币型基金历史数据
✅ `fund_financial_fund_daily_em` - 理财型基金实时数据
✅ `fund_financial_fund_info_em` - 理财型基金历史数据

## API参数映射表

| 功能 | 旧API | 新API | 参数变化 |
|------|-------|-------|----------|
| 基金排行 | `fund_rank_em?ranking_type=X&period=Y` | `fund_open_fund_rank_em?symbol=X` | ranking_type→symbol |
| 基金详情 | `fund_info_em?symbol=X` | `fund_open_fund_info_em?symbol=X&indicator=Y` | 添加indicator |
| 基金历史 | `fund_history_info_em?symbol=X&period=Y` | `fund_open_fund_info_em?symbol=X&indicator=Y&period=Z` | indicator+period |
| 基金持仓 | `fund_portfolio_em?symbol=X` | `fund_portfolio_hold_em?symbol=X&date=Y` | 添加date |
| 基金搜索 | `fund_search_em?keyword=X` | `fund_name_em` (客户端过滤) | 改为客户端过滤 |
| 基金公司 | `fund_company_em` | `fund_aum_em` | 使用专门的基金公司接口 |
| 基金类型 | `fund_type_em` | `fund_open_fund_rank_em?symbol=全部` | 使用基金排行接口获取类型信息 |
| 指数型基金 | 无 | `fund_info_index_em?symbol=X&indicator=Y` | 新增指数型基金专用接口 |
| 货币型基金 | 无 | `fund_money_fund_daily_em` | 新增货币型基金专用接口 |
| ETF分类 | 无 | `fund_etf_category_sina?symbol=X` | 新增ETF分类专用接口 |
| 基金估值 | 无 | `fund_value_estimation_em?symbol=X` | 新增基金估值专用接口 |

## 测试建议

1. **单元测试**: 验证修改后的API方法能正确调用新的端点
2. **集成测试**: 验证完整的数据流，从API调用到数据处理
3. **错误处理**: 确保新的API响应格式能被正确解析
4. **性能测试**: 验证客户端过滤逻辑的性能影响

## 注意事项

1. **向后兼容**: 部分接口的参数格式发生变化，调用方需要相应调整
2. **客户端处理**: 某些功能改为客户端处理，可能增加内存使用
3. **数据格式**: 新API返回的数据字段可能有所不同，需要验证数据解析逻辑
4. **错误处理**: 更新错误处理逻辑以适配新的API响应

## 验证状态

- ✅ 代码语法检查通过
- ✅ API端点映射完成
- ✅ 参数格式修正完成
- ✅ 调用方更新完成
- ⏳ 等待功能测试验证

## 总结

通过本次修正，项目中的所有基金API调用现在都符合官方文档规范，预计将显著减少因API参数不匹配导致的调用失败问题。