import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fund_exploration_page.dart';
import '../cubit/fund_exploration_cubit.dart';
import '../../../../../../core/di/di_initializer.dart' as sl;

/// 基金探索页面提供者
///
/// 为基金探索页面提供统一的Cubit状态管理
class FundExplorationProvider extends StatelessWidget {
  const FundExplorationProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl.sl<FundExplorationCubit>(),
      child: const FundExplorationPage(),
    );
  }
}
