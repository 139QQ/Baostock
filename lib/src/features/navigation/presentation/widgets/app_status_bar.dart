import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/state/global_cubit_manager.dart';
import '../../../../features/fund/presentation/widgets/realtime/connection_status_indicator.dart';
import '../../../../features/fund/presentation/cubits/realtime_data_cubit.dart';

class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0).withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBDBDBD).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // 实时连接状态指示器
            Builder(
              builder: (context) {
                final connectionCubit =
                    GlobalCubitManager.instance.getRealtimeConnectionCubit();
                if (connectionCubit != null) {
                  return BlocProvider.value(
                    value: connectionCubit,
                    child: const ConnectionStatusIndicator(
                      size: 16,
                      showLabel: true,
                    ),
                  );
                } else {
                  return const Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '离线',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(width: 16),

            // 数据更新时间
            Builder(
              builder: (context) {
                final realtimeCubit =
                    GlobalCubitManager.instance.getRealtimeDataCubit();
                if (realtimeCubit != null) {
                  return BlocBuilder<RealtimeDataCubit, RealtimeDataState>(
                    bloc: realtimeCubit,
                    builder: (context, state) {
                      final lastUpdateTime = state.lastUpdateTime;
                      if (lastUpdateTime != null) {
                        return Text(
                          '更新时间: ${_formatTime(lastUpdateTime)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF757575)),
                        );
                      } else {
                        return const Text(
                          '等待数据更新...',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF757575)),
                        );
                      }
                    },
                  );
                } else {
                  return const Text(
                    '数据更新时间: --',
                    style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  );
                }
              },
            ),
            const Spacer(),

            // 数据来源和基金数量
            Builder(
              builder: (context) {
                final realtimeCubit =
                    GlobalCubitManager.instance.getRealtimeDataCubit();
                if (realtimeCubit != null) {
                  return BlocBuilder<RealtimeDataCubit, RealtimeDataState>(
                    bloc: realtimeCubit,
                    builder: (context, state) {
                      final dataSource = state.dataSourceDescription ?? '未知';
                      final hasData = state.hasData;

                      return Row(
                        children: [
                          Text(
                            dataSource,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasData
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF757575),
                              fontWeight:
                                  hasData ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (hasData)
                            Text(
                              '实时数据: ${state.realtimeData.length} 项',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF757575)),
                            )
                          else
                            const Text(
                              '暂无实时数据',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF757575)),
                            ),
                        ],
                      );
                    },
                  );
                } else {
                  return const Text(
                    '基金数量: 10,542',
                    style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  );
                }
              },
            ),

            // 刷新按钮
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final realtimeCubit =
                    GlobalCubitManager.instance.getRealtimeDataCubit();
                if (realtimeCubit != null) {
                  realtimeCubit.refreshData();
                }
              },
              icon: const Icon(
                Icons.refresh,
                size: 16,
              ),
              iconSize: 16,
              tooltip: '刷新实时数据',
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
