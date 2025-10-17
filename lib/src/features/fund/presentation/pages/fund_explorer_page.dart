import 'package:flutter/material.dart';

class FundExplorerPage extends StatelessWidget {
  const FundExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金探索'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('基金探索', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('搜索和分析各类基金产品', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
