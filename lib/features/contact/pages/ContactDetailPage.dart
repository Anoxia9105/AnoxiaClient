import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/domain/Contact.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/DateUtil.dart';
import '../../../shared/widgets/AvatarWidget.dart';

/// 联系人详情页
///
/// 作者: anoxia
/// 日期: 2025/10/30 下午1:52
///
class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({super.key});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Contact> detail = context
        .read<ContactController>()
        .ContactDetail;

    return ValueListenableBuilder<Contact>(
      valueListenable: detail,
      builder: (context, value, _) {
        final user = value.contactUser;
        final name = value.remark?.isNotEmpty == true
            ? value.remark!
            : (user?.nickName ?? "(未命名用户)");

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 顶部头像区域 =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarWidget(
                    url: user?.avatar,
                    name: user?.nickName,
                    size: 80,
                  ),
                  const SizedBox(width: 16),
                  // 右侧信息
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 用户名和性别图标
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (user?.sex == "1")
                                Icon(
                                  HugeIcons.strokeRoundedFemale02,
                                  color: Colors.pink.shade600,
                                  size: 22,
                                )
                              else if (user?.sex == "0")
                                Icon(
                                  HugeIcons.strokeRoundedMale02,
                                  color: Colors.indigo.shade600,
                                  size: 22,
                                ),
                            ],
                          ),

                          // 操作按钮区
                          Row(
                            children: [
                              _buildIconButton(
                                tooltip: "发送消息",
                                icon: HugeIcons.strokeRoundedMessage01,
                                onPressed: () {},
                              ),
                              _buildIconButton(
                                tooltip: "语音通话",
                                icon: HugeIcons.strokeRoundedCall02,
                                onPressed: () {},
                              ),
                              _buildIconButton(
                                tooltip: "视频通话",
                                icon: HugeIcons.strokeRoundedVideo01,
                                onPressed: () {},
                              ),
                              _buildIconButton(
                                tooltip: "修改备注",
                                icon: HugeIcons.strokeRoundedEdit02,
                                onPressed: () {
                                  showEditDialog(context, value.remark ?? '');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // ===== 基本资料区域 =====
              _buildInfoRow(
                HugeIcons.strokeRoundedCall02,
                "手机号",
                user?.phonenumber ?? "未填写",
              ),
              _buildInfoRow(
                HugeIcons.strokeRoundedMail01,
                "邮箱",
                user?.email ?? "未填写",
              ),
              _buildInfoRow(
                HugeIcons.strokeRoundedUser,
                "用户昵称",
                user?.nickName ?? "未填写",
              ),
              _buildInfoRow(
                HugeIcons.strokeRoundedPencilEdit01,
                "个性签名",
                user?.remark ?? "未填写",
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                HugeIcons.strokeRoundedTime01,
                "认识时间",
                DateUtil.formatIsoDate(value.createdAt ?? ''),
              ),

              // ===== 备注信息 =====
              if (value.remark != null && value.remark!.isNotEmpty)
                Text(
                  "备注: ${value.remark!}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 通用图标按钮构造
  Widget _buildIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(icon: Icon(icon, size: 20), onPressed: onPressed),
    );
  }

  /// 通用信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text("$label：", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showEditDialog(BuildContext context, String remark) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("修改备注"),
          content: TextField(
            controller: TextEditingController(text: remark),
            decoration: const InputDecoration(
              hintText: "请输入备注",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
            TextButton(onPressed: () {}, child: Text("确定")),
          ],
        );
      },
    );
  }
}
