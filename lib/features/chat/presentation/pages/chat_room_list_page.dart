import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/list_retry_banner.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_dialog_menus.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_list_item.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_list_skeleton.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

/// 聊天房间列表页面
///
/// 展示所有聊天会话，支持：
/// - 搜索过滤
/// - 置顶/取消置顶
/// - 标记已读
/// - 删除/解散房间
/// - 下拉刷新
class ChatRoomList extends ConsumerStatefulWidget {
  const ChatRoomList({super.key});

  @override
  ConsumerState createState() => _ChatRoomListState();
}

class _ChatRoomListState extends ConsumerState<ChatRoomList> {
  /// 搜索框控制器
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        titleSpacing: 16,
        leading: () {
          /// 移动端（含窄屏 Web）显示菜单按钮 打开个人中心抽屉
          if (DeviceUtil.isMobile(context)) {
            return IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenuTwoLine),
              onPressed: () => ZoomDrawer.of(context)?.toggle(),
            );
          }
        }(),
        // title: () {
        //   /// 如果是桌面 显示搜索框
        //   if (DeviceUtil.isRealDesktop()) {
        //     return Row(
        //       children: [
        //         Expanded(
        //           child: SizedBox(
        //             child: TextField(
        //               controller: _searchController,
        //               onChanged: (val) => ref
        //                   .read(roomSearchQueryProvider.notifier)
        //                   .update(val),
        //               maxLength: 20,
        //               style: const TextStyle(fontSize: 14),
        //               decoration: InputDecoration(
        //                 counterText: '',
        //                 prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20),
        //                 // 有搜索内容时显示清除按钮
        //                 suffixIcon:
        //                     ref.watch(roomSearchQueryProvider).isNotEmpty
        //                     ? IconButton(
        //                         icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16),
        //                         onPressed: () {
        //                           _searchController.clear();
        //                           ref
        //                               .read(roomSearchQueryProvider.notifier)
        //                               .update('');
        //                         },
        //                       )
        //                     : null,
        //                 isDense: true,
        //                 contentPadding: EdgeInsets.zero,
        //                 hintText: 'chat_search_placeholder'.tr(),
        //                 border: OutlineInputBorder(
        //                   borderRadius: BorderRadius.circular(RadiusToken.xl),
        //                   borderSide: BorderSide.none,
        //                 ),
        //                 filled: true,
        //               ),
        //             ),
        //           ),
        //         ),
        //         const SizedBox(width: 8),
        //         // 添加房间/好友按钮
        //         Builder(
        //           builder: (context) {
        //             return IconButton(
        //               mouseCursor: SystemMouseCursors.click,
        //               icon: const HugeIcon(
        //                 icon: HugeIcons.strokeRoundedLayerAdd,
        //                 size: 20,
        //               ),
        //               onPressed: () =>
        //                   RoomListDialogMenus.showTopRightDialog(context),
        //             );
        //           },
        //         ),
        //       ],
        //     );
        //   }

        //   /// 移动端显示标题
        //   return Text('sidebar_chat'.tr());
        // }(),
        title: Text('sidebar_chat'.tr()),
        actions: [
          // 添加房间/好友按钮
          Builder(
            builder: (context) {
              return IconButton(
                mouseCursor: SystemMouseCursors.click,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLayerAdd,
                  size: 20,
                ),
                onPressed: () =>
                    RoomListDialogMenus.showTopRightDialog(context),
              );
            },
          ),
        ],
      ),
      // 异步状态处理
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    // 桌面布局（真实桌面 + 宽屏 Web）显示搜索栏，与底部输入栏的桌面判定一致
    final showSearch =
        DeviceUtil.isRealDesktop() ||
        (DeviceUtil.isRealWeb() && DeviceUtil.isDesktop(context));
    return Column(
      children: [
        if (showSearch) _buildSearchBar(context, ref),
        if (ref.watch(roomListRefreshFailedProvider) &&
            ref.watch(roomListServiceProvider).hasValue)
          ListRetryBanner(
            onRetry: () => ref.read(roomListServiceProvider.notifier).refresh(),
          ),
        Expanded(child: _buildRoomList(context, ref)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ), // 缩小上下间距
      child: SizedBox(
        height: 32, // 固定高度，更紧凑
        child: TextField(
          controller: _searchController,
          onChanged: (val) =>
              ref.read(roomSearchQueryProvider.notifier).update(val),
          maxLength: 20,
          style: const TextStyle(fontSize: 13), // 字体稍小
          decoration: InputDecoration(
            counterText: '',
            isDense: true, // 密集模式
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ), // 上下为0，垂直居中
            prefixIcon: const SizedBox(
              width: 30,
              height: 32,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 14,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: 30,
              height: 32,
            ),
            suffixIcon: ref.watch(roomSearchQueryProvider).isNotEmpty
                ? IconButton(
                    mouseCursor: SystemMouseCursors.click,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 14,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(roomSearchQueryProvider.notifier).update('');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                  )
                : null,
            hintText: 'chat_search_placeholder'.tr(),
            hintStyle: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建房间列表
  Widget _buildRoomList(BuildContext context, WidgetRef ref) {
    final filteredRooms = ref.watch(filteredSortedRoomListAsyncProvider);
    final query = ref.watch(roomSearchQueryProvider);

    return filteredRooms.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => const ChatRoomListSkeleton(),
      error: (error, _) => _buildErrorState(context, ref, error),
      data: (rooms) {
        if (rooms.isEmpty) {
          return _buildEmptyState(context, ref, query);
        }
        return RefreshIndicator(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return RoomListItem(
                key: ValueKey(rooms[index].roomId),
                id: rooms[index].roomId ?? '',
              );
            },
            clipBehavior: Clip.hardEdge,
          ),
        );
      },
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String query) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      backgroundColor: theme.scaffoldBackgroundColor,
      color: theme.colorScheme.primary,
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedComment01,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty
                        ? 'chat_no_conversations'.tr()
                        : 'chat_no_related_conversations'.tr(),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(roomListServiceProvider.notifier).refresh(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text('chat_rooms_action'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态视图
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      backgroundColor: theme.scaffoldBackgroundColor,
      color: theme.colorScheme.primary,
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 48,
                      color: theme.colorScheme.error.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'chat_load_failed'.tr(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(roomListServiceProvider.notifier).refresh(),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedReload,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text('call_window_retry'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
