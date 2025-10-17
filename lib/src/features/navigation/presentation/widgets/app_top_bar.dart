import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('基速基金分析器'),
      elevation: 1,
      actions: [
        const SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索基金代码或名称...',
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // TODO: 实现刷新功能
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: 打开设置
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // TODO: 显示关于信息
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
