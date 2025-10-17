import 'package:flutter/material.dart';

class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0).withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBDBDBD).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Text(
              '数据更新时间: 2024-08-28 15:30',
              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
            Spacer(),
            Text(
              '已连接',
              style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
            ),
            SizedBox(width: 16),
            Text(
              '基金数量: 10,542',
              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
          ],
        ),
      ),
    );
  }
}
