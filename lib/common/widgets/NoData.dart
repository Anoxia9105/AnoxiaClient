import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

/// 空数据占位组件
///
/// 当列表或内容为空时显示的占位提示，支持自定义标题、副文本和操作按钮。
class NoData extends StatelessWidget {
  /// 标题文本
  final String? title;

  /// 副标题/引导文本
  final String? subTitle;

  /// 按钮文本（配合 [onPressed] 使用）
  final String? buttonText;

  /// 自定义图标数据（默认使用邮件图标）
  final List<List<dynamic>>? iconData;

  /// 按钮点击回调（设置后需同时提供 [buttonText]）
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 顶部图标
            HugeIcon(
              icon: iconData ?? HugeIcons.strokeRoundedMailOpen01,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 25.h),
            // 标题
            Text(
              title ?? '暂无数据哦',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subTitle != null) ...[
              SizedBox(height: 10),
              Text(
                subTitle ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            // 操作按钮
            if (onPressed != null)
              OutlinedButton(
                onPressed: onPressed,
                child: Text(
                  buttonText ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
