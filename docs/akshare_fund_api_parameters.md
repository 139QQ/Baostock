# AKShare基金API参数文档（官方文档版）

基于AKShare官方文档和实际测试结果整理的基金相关API参数说明，适用于自建API服务 `http://154.44.25.92:8080/`。

## ⚠️ 重要说明
本文档已根据实际API测试结果进行了修正，仅包含**实际可用**的接口。

## 基金基础信息API

### 1. 获取基金列表
**接口地址**: `/api/public/fund_em_fund_name`
**功能**: 获取所有公募基金的基本信息列表
**请求方法**: GET
**参数**: 无

**返回数据格式**:
```json
[
  {
    "基金代码": "000001",
    "基金简称": "华夏成长混合",
    "基金类型": "混合型",
    "基金拼音": "huaxiachengchanghunhe"
  }
]
```

### 2. 获取基金详情
**接口地址**: `/api/public/fund_em_fund_info`
**功能**: 获取指定基金的详细基本信息
**请求方法**: GET
**参数**:
- `symbol` (必填): 基金代码，如 "000001"

**返回数据格式**:
```json
{
  "基金代码": "000001",
  "基金简称": "华夏成长混合",
  "单位净值": "1.2345",
  "累计净值": "2.3456",
  "日增长率": "1.23%",
  "成立日期": "2004-03-15",
  "基金公司": "华夏基金",
  "管理费率": "1.50%",
  "托管费率": "0.25%",
  "基金规模": "50.12亿元"
}
```

## 基金历史数据API

### 3. 获取基金历史净值
**接口地址**: `/api/public/fund_em_open_fund_info`
**功能**: 获取基金历史净值数据
**请求方法**: GET
**参数**:
- `symbol` (必填): 基金代码，如 "000001"
- `start_date` (必填): 开始日期，格式: "YYYY-MM-DD"
- `end_date` (必填): 结束日期，格式: "YYYY-MM-DD"

**返回数据格式**:
```json
[
  {
    "日期": "2024-08-28",
    "单位净值": "1.2345",
    "累计净值": "2.3456",
    "日增长率": "1.23%"
  }
]
```

## 基金排行榜API

### 4. 获取基金排行
**接口地址**: `/api/public/fund_em_rank`
**功能**: 获取基金排行榜数据
**请求方法**: GET
**参数**:
- `symbol` (必填): 排行类型，可选值：
  - "全部": 全部基金排行
  - "股票型": 股票型基金排行
  - "混合型": 混合型基金排行
  - "债券型": 债券型基金排行
  - "指数型": 指数型基金排行
  - "QDII": QDII基金排行
  - "LOF": LOF基金排行
  - "FOF": FOF基金排行
- `date` (可选): 查询日期，格式: "YYYY-MM-DD"，默认为最新日期

**返回数据格式**:
```json
[
  {
    "基金代码": "000001",
    "基金简称": "华夏成长混合",
    "日期": "2024-08-28",
    "单位净值": "1.2345",
    "累计净值": "2.3456",
    "日增长率": "1.23%",
    "近1周": "2.34%",
    "近1月": "5.67%",
    "近3月": "8.90%",
    "近6月": "12.34%",
    "近1年": "15.67%",
    "近2年": "25.89%",
    "近3年": "35.12%",
    "今年来": "10.23%",
    "成立来": "123.45%",
    "手续费": "1.50%",
    "起购金额": "100元"
  }
]
```

## 基金持仓信息API

### 5. 获取基金持仓
**接口地址**: `/api/public/fund_em_portfolio_hold`
**功能**: 获取基金持仓明细
**请求方法**: GET
**参数**:
- `symbol` (必填): 基金代码，如 "000001"

**返回数据格式**:
```json
{
  "股票持仓": [
    {
      "序号": "1",
      "股票代码": "000001.SZ",
      "股票名称": "平安银行",
      "占净值比例": "5.67%",
      "持股数": "1234567",
      "持仓市值": "12345678.90元"
    }
  ],
  "债券持仓": [
    {
      "序号": "1",
      "债券代码": "012345678",
      "债券名称": "21国债01",
      "占净值比例": "2.34%",
      "持仓数量": "10000",
      "市值": "1000000元"
    }
  ]
}
```

## 基金经理信息API

### 6. 获取基金经理信息
**接口地址**: `/api/public/fund_em_manager`
**功能**: 获取基金经理信息
**请求方法**: GET
**参数**:
- `symbol` (必填): 基金代码，如 "000001"

**返回数据格式**:
```json
{
  "基金经理": [
    {
      "姓名": "张三",
      "任职日期": "2020-01-01",
      "管理规模": "100亿元",
      "从业年限": "10年",
      "管理基金数量": "5只",
      "历史回报": "年化15.67%",
      "投资风格": "成长型"
    }
  ]
}
```

## 使用示例

### Dart/Flutter使用示例

```dart
import 'package:dio/dio.dart';

class FundApiService {
  static const String baseUrl = 'http://154.44.25.92:8080';
  
  final Dio _dio = Dio();
  
  // 获取基金列表
  Future<List<dynamic>> getFundList() async {
    final response = await _dio.get('$baseUrl/api/public/fund_em_fund_name');
    return response.data;
  }
  
  // 获取基金详情
  Future<Map<String, dynamic>> getFundDetail(String fundCode) async {
    final response = await _dio.get(
      '$baseUrl/api/public/fund_em_fund_info',
      queryParameters: {'symbol': fundCode},
    );
    return response.data;
  }
  
  // 获取历史净值
  Future<List<dynamic>> getFundHistory({
    required String fundCode,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '$baseUrl/api/public/fund_em_open_fund_info',
      queryParameters: {
        'symbol': fundCode,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return response.data;
  }
}
```

### 错误处理

所有API接口可能返回以下错误状态码：
- `400`: 参数错误
- `404`: 基金代码不存在
- `500`: 服务器内部错误
- `503`: 服务暂时不可用

### 注意事项

1. **日期格式**: 所有日期参数必须使用 "YYYY-MM-DD" 格式
2. **基金代码**: 使用6位数字代码，如 "000001"
3. **频率限制**: 建议添加适当的请求间隔，避免频繁调用
4. **数据缓存**: 建议对基金基本信息进行本地缓存，减少重复请求
5. **网络超时**: 建议设置合理的超时时间（10-30秒）

### 更新日志

- **2024-08-28**: 基于AKShare官方文档创建初始版本
- **API版本**: 对应AKShare 1.12.0+