import '../entities/fund.dart';
import '../repositories/fund_repository.dart';

/// 获取基金列表用例
class GetFundList {
  final FundRepository repository;

  GetFundList(this.repository);

  /// 执行获取基金列表操作
  Future<List<Fund>> call() async {
    return repository.getFundList();
  }
}
