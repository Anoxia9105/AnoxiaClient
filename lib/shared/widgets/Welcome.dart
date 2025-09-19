import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w), // 左右留白
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
            crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
            children: [
              // 顶部图标或插画
              HugeIcon(
                icon: HugeIcons.strokeRoundedChatting01,
                size: 60,
                // color: Colors.indigo.withValues(alpha: 0.8),
              ),
              SizedBox(height: 30.h), // 间距
              // 欢迎标题
              Text(
                "欢迎来到你的专属聊天空间",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15.h), // 间距
              // 欢迎副标题/提示语
              Text(
                "与朋友们畅聊，分享生活中的精彩瞬间！\n选择一个聊天室,开始你的对话吧。",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  // color: textColor.withValues(alpha: 0.7), // 副标题颜色稍微浅一些
                  height: 1.5, // 行高
                ),
              ),
            ],
          ),
        ),
      );
  }
}
