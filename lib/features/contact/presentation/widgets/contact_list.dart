import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/features/contact/presentation/pages/group_room_list_page.dart';
import 'package:anoxia/features/contact/presentation/pages/new_friends_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contact_groups_widget.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactList extends ConsumerWidget {
  const ContactList({super.key});

  void _openMobileDetail(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentViewType = ref.watch(
      contactSelectionProvider.select((s) => s.viewType),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(contactListServiceProvider.notifier).refresh();
      },
      child: Column(
        children: [
          _buildFunctionTile(
            ref: ref,
            icon: HugeIcons.strokeRoundedAddTeam,
            title: 'contact_new_friends'.tr(),
            isSelected: currentViewType == ContactViewType.newFriends,
            onTap: () {
              ref.read(contactSelectionProvider.notifier).selectNewFriends();
              if (DeviceUtil.isRealMobile()) {
                _openMobileDetail(context, const NewFriendsPage());
              }
            },
            trailing: VibratingBadge(
              count: ref.watch(pendingRequestCountProvider).value ?? 0,
            ),
          ),
          _buildFunctionTile(
            ref: ref,
            icon: HugeIcons.strokeRoundedUserGroup03,
            title: 'contact_joined_groups'.tr(),
            isSelected: currentViewType == ContactViewType.groups,
            onTap: () {
              ref.read(contactSelectionProvider.notifier).selectGroups();
              if (DeviceUtil.isRealMobile()) {
                _openMobileDetail(context, const GroupRoomListPage());
              }
            },
          ),
          ListTile(
            title: Text(
              'contact_contacts'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SortedContactGroupsWidget(
              onContactTap: () {
                if (DeviceUtil.isRealMobile()) {
                  _openMobileDetail(context, const ContactDetail());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionTile({
    required WidgetRef ref,
    required List<List<dynamic>> icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(ref.context).colorScheme;
    return ListTile(
      selected: isSelected,
      selectedTileColor: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      leading: HugeIcon(
        icon: icon,
        strokeWidth: 2,
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
      trailing: trailing,
    );
  }
}
