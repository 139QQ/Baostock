import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fund_exploration_page.dart';
import '../cubit/fund_exploration_cubit.dart';
import '../../../bloc/fund_ranking_bloc.dart';

/// 基金探索页面提供者
///
/// 为基金探索页面提供Bloc状态管理
class FundExplorationProvider extends StatelessWidget {
  const FundExplorationProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final fundRankingBloc = context.read<FundRankingBloc>();
        return FundExplorationCubit(fundRankingBloc: fundRankingBloc);
      },
      child: const FundExplorationPage(),
    );
  }
}
