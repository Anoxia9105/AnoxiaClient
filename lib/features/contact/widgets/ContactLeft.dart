import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:notepadclient/shared/widgets/NoData.dart';
import 'package:provider/provider.dart';

/// 联系人左侧导航栏
///
/// 作者: anoxia
///
/// 日期: 2025/10/30 下午1:54
///
class ContactLeft extends StatefulWidget {
  const ContactLeft({super.key});

  @override
  State<ContactLeft> createState() => _ContactLeftState();
}

class _ContactLeftState extends State<ContactLeft> {
  @override
  Widget build(BuildContext context) {
    final contact = context.read<ContactController>();

    List<AlphabetListViewItemGroup> tech = contact.buildContactGroups();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //头部检索框 & 添加好友
          buildHeader(),
          ...List.generate(contact.detailPageList.length, (index) {
            final item = contact.detailPageList[index];
            if (!item.show) {
              return const SizedBox.shrink();
            }
            // 列表项
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: ListTile(
                dense: true,
                leading: HugeIcon(icon: item.icon),
                title: Text(item.name),
                onTap: () {
                  contact.selectedIndex = index;
                },
                // trailing: VibratingBadge(messageCount: 2),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                ),
                selected: contact.selectedIndex == index,
              ),
            );
          }),
          tech.isEmpty
              ? Expanded(
                  child: NoData(
                    iconData: HugeIcons.strokeRoundedContact,
                    title: "暂无联系人哦",
                    onPressed: () {},
                    buttonText: "创建新的联系人",
                  ),
                )
              : Expanded(
                  child: AlphabetListView(
                    items: tech,
                    options: AlphabetListViewOptions(
                      listOptions: ListOptions(
                        //标题
                        listHeaderBuilder: (context, tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(tag),
                          );
                        },
                      ),
                      //右侧索引
                      scrollbarOptions: ScrollbarOptions(
                        symbols: DefaultScrollbarSymbols.alphabet
                      ),
                      //索引弹出框
                      overlayOptions: OverlayOptions(
                        overlayBuilder: (context, symbol) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.5),
                            ),
                            height: 40,
                            width: 40,
                            child: FittedBox(
                              child: Center(
                                child: Text(
                                  symbol,
                                  textScaler: TextScaler.noScaling,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        //检索框
        // 检索框
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch02,
                size: 18,
              ),
              hintStyle: TextStyle(fontSize: 12, height: 1.9),
              hintText: "搜索联系人",
              constraints: BoxConstraints(maxHeight: 30),
              border: OutlineInputBorder(),
              // contentPadding: EdgeInsets.symmetric(horizontal: 8,vertical: 8),
            ),
          ),
        ),
        SizedBox(width: 8),
        //按钮
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
        ),
      ],
    );
  }
}
