import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class NoData extends StatelessWidget {
  final String? title;
  final String? subTitle;
  final String? buttonText;
  final List<List<dynamic>>? iconData;
  final VoidCallback? onPressed;

  const NoData({
    super.key,
    this.onPressed,
    this.title,
    this.subTitle,
    this.buttonText,
    this.iconData,
  }) : assert(
         !(onPressed != null && (buttonText == null || buttonText == "")),
         '当 onPressed 不为 null 时，buttonText 不能为空',
       );

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
          crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
          children: [
            // 顶部图标或插画
            HugeIcon(
              icon: iconData ?? HugeIcons.strokeRoundedMailOpen01,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 25.h), // 间距
            // 提示标题
            Text(
              title ?? '暂无数据哦',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
           if(subTitle != null)
           ...[
             SizedBox(height: 10), // 间距
             // 引导文本
             Text(
               subTitle ?? '',
               textAlign: TextAlign.center,
               style: TextStyle(
                 fontSize: 15,
                 height: 1.4, // 行高
               ),
             ),
            ],
            SizedBox(height: 20.h), // 间距
            // 如果有创建新聊天的功能，可以添加一个按钮
            if (onPressed != null)
              OutlinedButton(
                onPressed: onPressed,
                child: Text(
                  buttonText ?? '',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
