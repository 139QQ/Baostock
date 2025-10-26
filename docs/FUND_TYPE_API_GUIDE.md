# 自选基金类型获取API指南

## 问题描述

当前自选基金添加功能中，所有基金都被硬编码为"混合型"，无法反映真实的基金类型。

## 数据源说明

### API基础信息
- **API地址**: `http://154.44.25.92:8080/api/public/fund_name_em`
- **请求方式**: GET
- **返回格式**: JSON
- **数据来源**: AKShare基金数据接口

### API参数说明
- **无参数**: 返回所有基金的基本信息列表
- **响应时间**: 通常2-5秒
- **更新频率**: 实时同步

## API返回数据结构

```json
[
  {
    "基金代码": "000001",
    "拼音缩写": "HXCZHH",
    "基金简称": "华夏成长混合",
    "基金类型": "混合型-灵活",
    "拼音全称": "HUAXIACHENGZHANGHUNHE"
  },
  {
    "基金代码": "000003",
    "拼音缩写": "ZHKZZZQA",
    "基金简称": "中海可转债债券A",
    "基金类型": "债券型-混合二级",
    "拼音全称": "ZHONGHAIKEZHUANZHAIZHAIQUANA"
  },
  {
    "基金代码": "000008",
    "拼音缩写": "JSZZ500ETFLJA",
    "基金简称": "嘉实中证500ETF联接A",
    "基金类型": "指数型-股票",
    "拼音全称": "JIASHIZHONGZHENG500ETFLIANJIEA"
  }
]
```

## 基金类型分类

### 主要类型
1. **股票型** - 主要投资股票市场的基金
2. **混合型** - 股票和债券混合投资的基金
3. **债券型** - 主要投资债券市场的基金
4. **指数型** - 跟踪特定指数的基金
5. **货币型** - 投资货币市场工具的基金
6. **QDII** - 投资海外市场的基金

### 子分类
- **混合型-灵活**: 灵活配置型混合基金
- **混合型-偏股**: 偏向股票投资的混合基金
- **债券型-混合二级**: 可投资股票的债券基金
- **债券型-长债**: 长期债券基金
- **指数型-股票**: 股票指数基金
- **指数型-海外股票**: 海外股票指数基金

## 使用示例

### 获取所有基金信息
```bash
curl -s "http://154.44.25.92:8080/api/public/fund_name_em"
```

### 查找特定基金类型
```bash
curl -s "http://154.44.25.92:8080/api/public/fund_name_em" | jq '.[] | select(.基金代码 == "000001")'
```

### 统计基金类型分布
```bash
curl -s "http://154.44.25.92:8080/api/public/fund_name_em" | jq -r '.[].基金类型' | sort | uniq -c
```

## 解决方案

### 1. API调用获取基金类型
在添加自选基金时，通过 `fund_name_em` API 获取真实的基金类型：

```dart
Future<String> getFundType(String fundCode) async {
  try {
    final response = await http.get(
      Uri.parse('http://154.44.25.92:8080/api/public/fund_name_em'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> funds = json.decode(response.body);
      final fund = funds.firstWhere(
        (f) => f['基金代码'] == fundCode,
        orElse: () => null,
      );

      if (fund != null && fund['基金类型'] != null) {
        String fundType = fund['基金类型'].toString();
        // 简化显示：只取主要类型
        if (fundType.contains('-')) {
          fundType = fundType.split('-')[0];
        }
        return fundType;
      }
    }
  } catch (e) {
    print('获取基金类型失败: $e');
  }
  return '混合型'; // 默认值
}
```

### 2. 类型映射规则
- `混合型-灵活` → `混合型`
- `债券型-混合二级` → `债券型`
- `指数型-股票` → `指数型`
- `货币型-普通货币` → `货币型`

## 注意事项

1. **网络依赖**: API调用需要网络连接
2. **超时处理**: 建议设置10秒超时
3. **错误处理**: API失败时使用默认类型
4. **数据缓存**: 可考虑缓存基金类型信息
5. **并发控制**: 避免同时发起过多API请求

## 相关接口

### 其他基金信息接口
- `fund_open_fund_rank_em` - 基金排行榜
- `fund_open_fund_daily_em` - 实时行情
- `fund_open_fund_info_em` - 历史净值数据

### 完整API文档
参考 `docs/fund_api_parameters.md` 获取详细的API参数说明。

## 测试用例

### 验证基金类型获取
```dart
// 测试代码: 000001 应该返回 "混合型"
// 测试代码: 000003 应该返回 "债券型"
// 测试代码: 000008 应该返回 "指数型"
```

### 常见基金代码示例
- `000001` - 华夏成长混合 → `混合型`
- `110022` - 易方达消费行业股票 → `股票型`
- `161725` - 招商中证白酒指数分级 → `指数型`
- `519066` - 汇添富蓝筹稳健混合 → `混合型`
- `000198` - 天弘余额宝货币 → `货币型`