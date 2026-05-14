import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../framework/domain/ChatContactVO.dart';
import '../../../framework/domain/ChatRoomVO.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_list_controller.dart';
import '../../../framework/provider/contact/contact_selection_controller.dart';
import '../../../gen/assets.gen.dart';

class DesktopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  // 是否隐藏应用栏Logo
  final bool hideAppBarLogo;
  // 是否显示增强内容（搜索、状态点、快捷新建）
  final bool showHeaderEnhancements;

  const DesktopAppBar({
    super.key,
    this.hideAppBarLogo = false,
    this.showHeaderEnhancements = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extended = ref.watch(
      layoutControllerProvider.select((r) => r.extendedValue),
    );

    return AppBar(
      elevation: 0,
      titleSpacing: 4,
      leading: hideAppBarLogo
          ? SizedBox.shrink()
          : Center(
              child: Assets.images.appIconPng.image(
                width: 24,
                height: 24,
                // fit: BoxFit.cover
              ),
            ),
      actions: [
        if (showHeaderEnhancements) ...[
          _HeaderSearchEntry(onTap: () => _openGlobalSearch(context, ref)),
          const SizedBox(width: 6),
        ],
        //最小化
        IconButton(
          tooltip: "header_minimize".tr(),
          padding: EdgeInsets.zero,
          onPressed: () {
            windowManager.minimize();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedSolidLine01,
            // color: widget.iconColor,
            size: 18,
          ),
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        //正常/最大化
        changeScreenMode(extended),
        IconButton(
          tooltip: "header_closure".tr(),
          padding: EdgeInsets.zero,
          hoverColor: Colors.red,
          onPressed: () {
            windowManager.hide();
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white;
              }
              return null;
            }),
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 20,
            // color: widget.iconColor,
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
    );
  }

  Widget changeScreenMode(bool mode) {
    if (mode) {
      return IconButton(
        tooltip: "header_reduction".tr(),
        padding: EdgeInsets.zero,
        onPressed: () {
          windowManager.unmaximize();
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          // color: widget.iconColor,
          size: 18,
        ),
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: "header_maximize".tr(),
      padding: EdgeInsets.zero,
      onPressed: () {
        windowManager.maximize();
      },
      icon: HugeIcon(
        // color: widget.iconColor,
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  void _openGlobalSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _GlobalSearchDialog(ref: ref),
    );
  }
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _GlobalSearchDialog({required this.ref});

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rooms = ref.watch(roomListServiceProvider).value ?? <ChatRoomVO>[];
    final contactsMap =
        ref.watch(contactListServiceProvider).value ?? <int, ChatContactVO>{};
    final contacts = contactsMap.values.toList();

    final q = _query.trim().toLowerCase();
    final roomResults = q.isEmpty
        ? <ChatRoomVO>[]
        : rooms
              .where((r) {
                final roomName = (r.roomName ?? '').toLowerCase();
                final lastMsg = (r.lastMessage?.content ?? '').toLowerCase();
                return roomName.contains(q) || lastMsg.contains(q);
              })
              .take(8)
              .toList();

    final contactResults = q.isEmpty
        ? <ChatContactVO>[]
        : contacts
              .where((c) {
                final name = (c.nickName ?? '').toLowerCase();
                final remark = (c.remark ?? '').toLowerCase();
                final idText = (c.contactId?.toString() ?? '');
                return name.contains(q) ||
                    remark.contains(q) ||
                    idText.contains(q);
              })
              .take(8)
              .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 80),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: '${'search'.tr()}（会话 / 联系人）',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixText: 'Ctrl+K',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: q.isEmpty
                  ? Center(
                      child: Text(
                        '输入关键词以搜索会话和联系人',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [
                        _ResultSectionTitle(title: '会话'),
                        if (roomResults.isEmpty)
                          _ResultEmpty(text: '未找到相关会话')
                        else
                          ...roomResults.map(
                            (room) => _ResultTile(
                              icon: room.roomType == 1
                                  ? Icons.groups_2_outlined
                                  : Icons.person_outline,
                              title:
                                  room.roomName ??
                                  'chat_unknown_conversation'.tr(),
                              subtitle: room.lastMessage?.content ?? '',
                              onTap: () {
                                widget.ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(0);
                                if (room.roomId != null) {
                                  widget.ref
                                      .read(activeRoomIdProvider.notifier)
                                      .setActive(room.roomId!);
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        _ResultSectionTitle(title: '联系人'),
                        if (contactResults.isEmpty)
                          _ResultEmpty(text: '未找到相关联系人')
                        else
                          ...contactResults.map(
                            (contact) => _ResultTile(
                              icon: Icons.badge_outlined,
                              title: contact.remark?.isNotEmpty == true
                                  ? contact.remark!
                                  : (contact.nickName ??
                                        'chat_unknown_user'.tr()),
                              subtitle:
                                  'ID: ${contact.contactId ?? '-'} · ${contact.nickName ?? ''}',
                              onTap: () {
                                widget.ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(1);
                                widget.ref
                                    .read(contactSelectionProvider.notifier)
                                    .selectContact(contact);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSectionTitle extends StatelessWidget {
  final String title;

  const _ResultSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ResultEmpty extends StatelessWidget {
  final String text;

  const _ResultEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _HeaderSearchEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderSearchEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 30,
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 15, color: colorScheme.outline),
            const SizedBox(width: 6),
            SizedBox(
              width: 145,
              child: Text(
                '${'search'.tr()}  Ctrl+K',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
