import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:notepadclient/shared/widgets/NoData.dart';
import 'package:provider/provider.dart';

class ContactLeft extends StatefulWidget {
  const ContactLeft({super.key});

  @override
  State<ContactLeft> createState() => _ContactLeftState();
}

class _ContactLeftState extends State<ContactLeft> {
  // final List<AlphabetListViewItemGroup> tech = [
  //   AlphabetListViewItemGroup(
  //     tag: 'A',
  //     children: const [Text('Apple'), Text('Amazon'), Text('Alibaba')],
  //   ),
  //   AlphabetListViewItemGroup(
  //     tag: 'I',
  //     children: const [Text('Intel'), Text('IBM')],
  //   ),
  // ];
  /// 日语五十音顺 + '#'（非日语字符）
  static const List<String> japaneseAlphabet = [
    'あ', // a行
    'い',
    'う',
    'え',
    'お',
    'か', // ka行
    'き',
    'く',
    'け',
    'こ',
    'さ', // sa行
    'し',
    'す',
    'せ',
    'そ',
    'た', // ta行
    'ち',
    'つ',
    'て',
    'と',
    'な', // na行
    'に',
    'ぬ',
    'ね',
    'の',
    'は', // ha行
    'ひ',
    'ふ',
    'へ',
    'ほ',
    'ま', // ma行
    'み',
    'む',
    'め',
    'も',
    'や', // ya行
    'ゆ',
    'よ',
    'ら', // ra行
    'り',
    'る',
    'れ',
    'ろ',
    'わ', // wa行
    'を',
    'ん', // n
    '#', // 非日语或特殊字符
  ];

  @override
  Widget build(BuildContext context) {
    final contact = context.read<ContactController>();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildHeader(),
          ...List.generate(contact.detailPageList.length, (index){
            final item = contact.detailPageList[index];
            if(!item.show){
              return const SizedBox.shrink();
            }
            return  ListTile(
              dense: true,
              leading: HugeIcon(
                icon: item.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(item.name),
              onTap: () {
                contact.selectedIndex=index;
              },
              // trailing: VibratingBadge(messageCount: 2),
              trailing: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
              ),
            );
          }),
          contact.tech.isEmpty
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
                    items: contact.tech,
                    options: AlphabetListViewOptions(
                      listOptions: ListOptions(
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
                      scrollbarOptions: ScrollbarOptions(
                        symbols: DefaultScrollbarSymbols.alphabet,
                        // backgroundColor: Colors.yellow,
                      ),
                      overlayOptions: OverlayOptions(
                        overlayBuilder: (context, symbol) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.8),
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
