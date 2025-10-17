# 编码规范与标准

## 1. 概述

本文档定义了基速基金量化分析平台的编码规范和标准，确保代码质量、可读性和可维护性。所有开发人员必须遵循这些规范进行代码编写。

## 2. Dart语言规范

### 2.1 命名规范

#### 2.1.1 标识符命名
| 类型 | 格式 | 示例 |
|------|------|------|
| 类名 | PascalCase | `FundDetailPage` |
| 变量名 | camelCase | `fundName` |
| 常量名 | lower_snake_case | `max_fund_count` |
| 文件名 | lower_snake_case | `fund_detail_page.dart` |
| 包名 | lower_snake_case | `fund_repository.dart` |
| 私有成员 | 下划线前缀 | `_privateVariable` |

#### 2.1.2 命名最佳实践
```dart
// ✅ 正确命名
class FundPerformanceCalculator {
  static const int maxHistoricalYears = 5;
  final String fundCode;
  double _internalRate = 0.0;

  double calculateAnnualizedReturn(List<double> returns) {
    // 实现代码
  }
}

// ❌ 错误命名
class fundPerformanceCalculator {  // 类名应使用PascalCase
  static const int MAX_HISTORICAL_YEARS = 5;  // 常量应使用lower_snake_case
  final String fund_code;  // 变量名应使用camelCase
  double internalRate = 0.0;  // 私有变量应以下划线开头

  double calc(List<double> r) {  // 方法名不清晰
    // 实现代码
  }
}
```

### 2.2 代码格式

#### 2.2.1 缩进和空格
- 使用2个空格进行缩进（不使用Tab）
- 在操作符两侧添加空格
- 在逗号后添加空格
- 在冒号后添加空格

```dart
// ✅ 正确格式
class FundAnalyzer {
  double calculateSharpeRatio(List<double> returns, double riskFreeRate) {
    final double averageReturn = returns.reduce((a, b) => a + b) / returns.length;
    final double standardDeviation = calculateStandardDeviation(returns);

    return (averageReturn - riskFreeRate) / standardDeviation;
  }
}

// ❌ 错误格式
class FundAnalyzer{
  double calculateSharpeRatio(List<double>returns,double riskFreeRate){
    final double averageReturn=returns.reduce((a,b)=>a+b)/returns.length;
    final double standardDeviation=calculateStandardDeviation(returns);

    return(averageReturn-riskFreeRate)/standardDeviation;
  }
}
```

#### 2.2.2 大括号风格
- 使用K&R风格的大括号
- 控制结构始终使用大括号

```dart
// ✅ 正确风格
if (fund != null) {
  return fund.name;
} else {
  return 'Unknown Fund';
}

// ❌ 错误风格
if (fund != null)
  return fund.name;
else
  return 'Unknown Fund';
```

#### 2.2.3 行长度限制
- 每行代码不超过80个字符
- 长表达式应适当换行
- 换行时保持逻辑一致性

```dart
// ✅ 正确换行
final double annualizedReturn = Math.pow(
  cumulativeReturn,
  1 / years
) - 1;

// ❌ 错误换行
final double annualizedReturn = Math.pow(cumulativeReturn, 1 /
years) - 1;
```

### 2.3 注释规范

#### 2.3.1 文档注释
- 使用`///`进行文档注释
- 公共API必须有完整的文档注释
- 注释应描述"为什么"而非"做什么"

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

#### 2.3.2 实现注释
- 使用`//`进行实现注释
- 注释应解释复杂的业务逻辑
- 避免显而易见的注释

```dart
// ✅ 有价值的注释
// 由于API返回的数据格式不统一，需要特殊处理负值情况
if (returnValue.startsWith('(') && returnValue.endsWith(')')) {
  // 移除括号并添加负号
  returnValue = '-' + returnValue.substring(1, returnValue.length - 1);
}

// ❌ 无价值的注释
// 增加计数器
counter++;  // 显而易见的操作不需要注释
```

#### 2.3.3 TODO注释
- 使用`TODO:`标记待完成的工作
- 包含作者和日期信息
- 描述具体需要完成的内容

```dart
// TODO(username): 2025-09-26 - 需要添加对货币基金的特殊处理逻辑
// 当前实现仅适用于股票型和混合型基金
if (fund.type == FundType.moneyMarket) {
  return calculateMoneyMarketReturn(fund);
}
```

## 3. Flutter/Dart特定规范

### 3.1 Widget构建

#### 3.1.1 Widget类定义
- 使用`const`构造函数当可能时
- 按照`key, child, children`的顺序排列参数
- 复杂的Widget应拆分为独立方法或类

```dart
// ✅ 正确的Widget定义
class FundCard extends StatelessWidget {
  const FundCard({
    Key? key,
    required this.fund,
    this.onTap,
  }) : super(key: key);

  final Fund fund;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: InkWell(
        onTap: onTap,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildPerformance(),
        ],
      ),
    );
  }
}
```

#### 3.1.2 状态管理
- 使用`final`声明不变的变量
- 避免在`build`方法中进行耗时操作
- 使用`const`构造函数创建不变的Widget

```dart
// ✅ 正确的状态管理
class FundList extends StatelessWidget {
  const FundList({Key? key, required this.funds}) : super(key: key);

  final List<Fund> funds;

  @override
  Widget build(BuildContext context) {
    // 避免在build方法中进行复杂计算
    return ListView.builder(
      itemCount: funds.length,
      itemBuilder: (context, index) {
        return FundCard(fund: funds[index]);  // 使用const构造函数
      },
    );
  }
}
```

### 3.2 异步编程

#### 3.2.1 async/await使用
- 优先使用`async/await`而非`.then()`
- 正确处理异常
- 避免不必要的`async`修饰符

```dart
// ✅ 正确的异步处理
Future<List<Fund>> fetchFunds() async {
  try {
    final response = await apiClient.getFunds();
    return response.data.map((json) => Fund.fromJson(json)).toList();
  } on DioException catch (e) {
    // 处理特定的网络异常
    throw FundApiException('Failed to fetch funds: ${e.message}');
  } catch (e) {
    // 处理其他异常
    throw FundApiException('Unexpected error: $e');
  }
}

// ❌ 错误的异步处理
Future<List<Fund>> fetchFunds() async {  // 不需要async
  return apiClient.getFunds().then((response) {
    return response.data.map((json) => Fund.fromJson(json)).toList();
  }).catchError((error) {
    throw Exception(error);
  });
}
```

#### 3.2.2 Stream使用
- 正确管理Stream订阅
- 使用`async*`生成器函数
- 及时取消订阅避免内存泄漏

```dart
// ✅ 正确的Stream使用
class FundPriceBloc extends Bloc<FundPriceEvent, FundPriceState> {
  StreamSubscription? _priceSubscription;

  @override
  Future<void> close() {
    _priceSubscription?.cancel();  // 取消订阅
    return super.close();
  }

  Stream<FundPrice> _watchFundPrice(String fundCode) async* {
    await for (final price in priceService.watchPrice(fundCode)) {
      yield FundPrice.fromDto(price);
    }
  }
}
```

## 4. 错误处理

### 4.1 异常类型定义
- 定义专门的异常类型
- 提供有意义的错误信息
- 包含足够的上下文信息

```dart
// ✅ 良好的异常定义
class FundApiException implements Exception {
  const FundApiException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'FundApiException: $message${code != null ? ' (Code: $code)' : ''}';
}

class FundNotFoundException extends FundApiException {
  const FundNotFoundException(String fundCode)
      : super('Fund $fundCode not found', code: 'FUND_NOT_FOUND');
}
```

### 4.2 错误处理模式
- 在适当的层级处理错误
- 提供用户友好的错误信息
- 记录错误日志便于调试

```dart
// ✅ 正确的错误处理
class FundBloc extends Bloc<FundEvent, FundState> {
  @override
  Stream<FundState> mapEventToState(FundEvent event) async* {
    if (event is FetchFundDetail) {
      yield FundLoadInProgress();

      try {
        final fund = await repository.getFund(event.fundCode);
        yield FundLoadSuccess(fund);
      } on FundNotFoundException catch (e) {
        // 处理特定异常
        yield FundLoadFailure('基金代码不存在，请检查输入');
        logger.warning('Fund not found: ${event.fundCode}', e);
      } on FundApiException catch (e) {
        // 处理API异常
        yield FundLoadFailure('网络连接失败，请稍后重试');
        logger.error('API error fetching fund: ${event.fundCode}', e);
      } catch (e) {
        // 处理未预期的异常
        yield FundLoadFailure('发生未知错误，请联系客服');
        logger.error('Unexpected error', e);
      }
    }
  }
}
```

## 5. 性能优化

### 5.1 Widget性能
- 使用`const`构造函数
- 避免在`build`方法中创建对象
- 使用`keys`优化列表性能

```dart
// ✅ 性能优化的Widget
class OptimizedFundList extends StatelessWidget {
  const OptimizedFundList({Key? key, required this.funds}) : super(key: key);

  final List<Fund> funds;

  @override
  Widget build(BuildContext context) {
    // 使用const构造函数
    return ListView.builder(
      itemCount: funds.length,
      itemBuilder: (context, index) {
        return FundCard(
          key: ValueKey(funds[index].code),  // 使用稳定的key
          fund: funds[index],
        );
      },
    );
  }
}

// ❌ 性能差的Widget
class PoorFundList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final funds = Provider.of<FundBloc>(context).state.funds;

    return ListView.builder(
      itemCount: funds.length,
      itemBuilder: (context, index) {
        // 每次build都创建新对象
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Text(funds[index].name),
        );
      },
    );
  }
}
```

### 5.2 内存管理
- 及时释放资源
- 避免内存泄漏
- 使用弱引用当适当时

```dart
// ✅ 正确的资源管理
class FundDataManager {
  Timer? _refreshTimer;
  StreamSubscription? _dataSubscription;

  void start() {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _refreshData(),
    );
  }

  void dispose() {
    _refreshTimer?.cancel();  // 取消定时器
    _dataSubscription?.cancel();  // 取消订阅
  }
}
```

## 6. 测试规范

### 6.1 测试命名
- 使用描述性的测试名称
- 遵循`when_then`或`given_when_then`模式
- 覆盖正常情况和边界情况

```dart
// ✅ 良好的测试命名
group('FundRepository', () {
  group('getFund', () {
    test('should return fund when fund exists', () async {
      // 测试实现
    });

    test('should throw FundNotFoundException when fund does not exist', () async {
      // 测试实现
    });

    test('should throw FundApiException when API fails', () async {
      // 测试实现
    });
  });
});
```

### 6.2 测试结构
- 使用`arrange-act-assert`模式
- 保持测试简单明了
- 避免测试间的依赖

```dart
test('should calculate annualized return correctly', () {
  // Arrange
  final calculator = ReturnCalculator();
  final returns = [0.1, 0.2, 0.3];

  // Act
  final result = calculator.calculateAnnualized(returns);

  // Assert
  expect(result, closeTo(0.197, 0.001));
});
```

## 7. 安全规范

### 7.1 数据安全
- 敏感数据加密存储
- 避免在日志中记录敏感信息
- 验证所有用户输入

```dart
// ✅ 安全的数据处理
class SecureStorage {
  static const String _encryptionKey = 'fund_app_key_2024';

  static String encryptSensitiveData(String data) {
    // 使用AES加密敏感数据
    final key = Key.fromUtf8(_encryptionKey);
    final encrypter = Encrypter(AES(key));
    return encrypter.encrypt(data).base64;
  }

  static String sanitizeForLogging(String input) {
    // 移除或掩盖敏感信息
    return input.replaceAll(RegExp(r'\d{6}'), '******');
  }
}
```

### 7.2 网络安全
- 使用HTTPS进行网络通信
- 验证SSL证书
- 实施请求重试机制

```dart
// ✅ 安全的网络配置
class SecureApiClient {
  final Dio _dio;

  SecureApiClient() : _dio = Dio() {
    _dio.options.baseUrl = 'https://api.jisufund.com';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // 证书验证
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // 验证证书
        return _verifyCertificate(cert, host);
      };
    };
  }
}
```

## 8. 版本管理

### 8.1 Git提交规范
- 使用清晰的提交信息
- 遵循`type: description`格式
- 关联相关的issue

```
feat: 添加基金详情页面

- 实现基金基础信息展示
- 添加历史业绩图表
- 支持基金收藏功能

Closes #123
```

### 8.2 代码审查
- 所有代码必须经过审查
- 关注代码质量和规范遵循
- 确保测试覆盖

---

**最后更新**: 2025-09-26
**维护者**: 开发团队
**审核状态**: 已审核
**关联文档**: [源代码结构](./source-tree.md), [架构文档](../architecture.md)"}