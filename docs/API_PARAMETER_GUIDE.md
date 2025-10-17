# 基金API参数文档

## 概述
本文档详细说明了基速基金分析器使用的AKShare API接口参数，包括基金列表、基金排行、基金详情等核心功能所需的参数。

## 基础信息
- **API基础地址**: `http://154.44.25.92:8080/`

- **请求格式**: GET请求
- **响应格式**: JSON
- **超时设置**: 10秒

## API接口列表

### 1. 获取基金列表
**接口路径**: `/api/public/fund_name_em`

**功能描述**: 获取所有基金的名称和基本信息列表

**请求参数**:
- 无

**返回字段**:
| 字段名 | 类型 | 描述 |
|--------|------|------|
| 基金代码 | String | 基金的唯一标识符 |
| 基金简称 | String | 基金的简称名称 |
| 基金类型 | String | 基金类型（股票型、混合型、债券型等） |
| 基金管理人 | String | 基金管理公司名称 |
| 基金托管人 | String | 基金托管银行名称 |
| 成立日期 | String | 基金成立日期 |
| 管理费率 | String | 年度管理费率 |
| 托管费率 | String | 年度托管费率 |

**示例调用**:
```dart
final response = await http.get(
  Uri.parse('http://154.44.25.92:8080/api/public/fund_name_em'),
  headers: {'Accept': 'application/json'},
);
```

### 2. 获取基金排行
**接口路径**: `/api/public/fund_open_fund_rank_em`

**功能描述**: 获取各类基金的排行数据

**请求参数**:
| 参数名 | 类型 | 是否必需 | 描述 |
|--------|------|----------|------|
| symbol | String | 是 | 基金类型分类（见下表） |

**symbol参数值**:
| 值 | 描述 |
|----|------|
| 全部 | 全部基金 |
| 股票型 | 股票型基金 |
| 混合型 | 混合型基金 |
| 债券型 | 债券型基金 |
| 指数型 | 指数型基金 |
| QDII | QDII基金 |
| LOF | LOF基金 |
| FOF | FOF基金 |

**返回字段**:
| 字段名 | 类型 | 描述 |
|--------|------|------|
| 基金代码 | String | 基金代码 |
| 基金简称 | String | 基金名称 |
| 单位净值 | String | 当前单位净值 |
| 累计净值 | String | 累计净值 |
| 日增长率 | String | 当日涨跌幅百分比 |
| 近1周 | String | 近1周收益率 |
| 近1月 | String | 近1月收益率 |
| 近3月 | String | 近3月收益率 |
| 近6月 | String | 近6月收益率 |
| 近1年 | String | 近1年收益率 |
| 近2年 | String | 近2年收益率 |
| 近3年 | String | 近3年收益率 |
| 今年来 | String | 今年以来收益率 |
| 成立来 | String | 成立以来收益率 |
| 手续费 | String | 申购手续费率 |

**示例调用**:
```dart
// 获取股票型基金排行
final response = await http.get(
  Uri.parse('http://154.44.25.92:8080/api/public/fund_open_fund_rank_em?symbol=股票型'),
  headers: {'Accept': 'application/json'},
);
```

### 3. 获取基金历史净值
**接口路径**: `/api/public/fund_open_fund_info`

**功能描述**: 获取指定基金的历史净值数据

**请求参数**:
| 参数名 | 类型 | 是否必需 | 描述 |
|--------|------|----------|------|
| fund | String | 是 | 基金代码 |

**返回字段**:
| 字段名 | 类型 | 描述 |
|--------|------|------|
| 净值日期 | String | 净值发布日期 |
| 单位净值 | String | 当日单位净值 |
| 累计净值 | String | 当日累计净值 |
| 日增长率 | String | 当日涨跌幅 |

**示例调用**:
```dart
// 获取易方达蓝筹精选混合(005827)历史净值
final response = await http.get(
  Uri.parse('http://154.44.25.92:8080/api/public/fund_open_fund_info?fund=005827')(不存在),
  headers: {'Accept': 'application/json'},
);
```

### 4. 获取基金基本信息
**接口路径**: `/api/public/fund_em_info`

**功能描述**: 获取基金的详细基本信息

**请求参数**:
| 参数名 | 类型 | 是否必需 | 描述 |
|--------|------|----------|------|
| fund | String | 是 | 基金代码 |

**返回字段**:
| 字段名 | 类型 | 描述 |
|--------|------|------|
| 基金简称 | String | 基金简称 |
| 基金类型 | String | 基金类型 |
| 基金代码 | String | 基金代码 |
| 成立日期 | String | 成立日期 |
| 管理人 | String | 基金管理人 |
| 托管人 | String | 基金托管人 |
| 基金经理 | String | 基金经理姓名 |
| 投资目标 | String | 投资目标描述 |
| 投资理念 | String | 投资理念描述 |

## 错误处理

### 状态码说明
| 状态码 | 描述 | 处理方式 |
|--------|------|----------|
| 200 | 请求成功 | 正常处理数据 |
| 400 | 参数错误 | 检查参数格式和值 |
| 404 | 接口不存在 | 检查接口路径 |
| 500 | 服务器错误 | 稍后重试 |
| 超时 | 请求超时 | 检查网络连接 |

### 常见错误示例
```dart
try {
  final response = await http.get(uri).timeout(Duration(seconds: 10));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('API错误: ${response.statusCode}');
  }
} catch (e) {
  if (e is SocketException) {
    throw Exception('网络连接失败');
  } else if (e is TimeoutException) {
    throw Exception('请求超时');
  } else {
    throw Exception('未知错误: $e');
  }
}
```

## 基金代码说明

### 常见基金代码前缀
| 前缀 | 基金类型 | 示例 |
|------|----------|------|
| 00 | 股票型 | 005827（易方达蓝筹精选混合） |
| 51 | 货币型 | 511990（华宝添益货币ETF） |
| 16 | 混合型 | 161725（招商中证白酒指数） |
| 50 | 债券型 | 501009（华安黄金ETF联接A） |

### 获取基金代码的方法
1. **基金列表接口**: 使用 `/api/public/fund_name_em` 获取所有基金代码
2. **基金排行接口**: 使用 `/api/public/fund_open_fund_rank_em` 获取热门基金
3. **手动查询**: 通过基金公司官网或天天基金网查询

## 数据更新频率

### 实时数据
- 基金排行：每日更新
- 基金净值：每个交易日15:00后更新
- 基金基本信息：定期更新

### 历史数据
- 历史净值：可获取基金成立以来的所有数据
- 历史排行：可获取近3年的排行数据

## 使用建议

### 最佳实践
1. **批量请求**: 避免频繁请求，可缓存常用数据
2. **错误重试**: 实现重试机制，最多重试3次
3. **数据缓存**: 基金基本信息可缓存24小时
4. **分页处理**: 大数据量请求时考虑分页

### 性能优化
- 使用本地缓存减少API调用
- 实现请求去重，避免重复请求
- 设置合理的超时时间（10-15秒）
- 使用异步请求避免阻塞UI

## 相关资源

- [AKShare官方文档](https://akshare.akfamily.xyz/data/fund/fund_public.html)
- [测试工具](D:\Git\Github\Baostock\test_api.dart)
- [Flutter集成示例](D:\Git\Github\Baostock\lib\src\core\network\api_service.dart)