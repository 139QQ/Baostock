import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/bloc/fund_exploration_state.dart';

// 直接实现Mock类以避免代码生成问题
class MockFundExplorationCubit extends MockCubit<FundExplorationState>
    implements FundExplorationCubit {
  @override
  void initialize() {
    super.noSuchMethod(Invocation.method(#initialize, []));
  }

  @override
  void searchFunds(String query) {
    super.noSuchMethod(Invocation.method(#searchFunds, [query]));
  }

  @override
  void applyFilters({
    String? fundType,
    String? sortBy,
    String? minReturn,
    String? maxReturn,
  }) {
    super.noSuchMethod(Invocation.method(#applyFilters, [], {
      #fundType: fundType,
      #sortBy: sortBy,
      #minReturn: minReturn,
      #maxReturn: maxReturn,
    }));
  }

  @override
  void updateSortBy(String sortBy) {
    super.noSuchMethod(Invocation.method(#updateSortBy, [sortBy]));
  }

  @override
  void addToComparison(dynamic fund) {
    super.noSuchMethod(Invocation.method(#addToComparison, [fund]));
  }

  @override
  void removeFromComparison(String fundCode) {
    super.noSuchMethod(Invocation.method(#removeFromComparison, [fundCode]));
  }

  @override
  void clearComparison() {
    super.noSuchMethod(Invocation.method(#clearComparison, []));
  }

  @override
  void setActiveView(FundExplorationView view) {
    super.noSuchMethod(Invocation.method(#setActiveView, [view]));
  }
}

// 基础MockCubit类
class MockCubit<State> extends Mock implements Cubit<State> {}
