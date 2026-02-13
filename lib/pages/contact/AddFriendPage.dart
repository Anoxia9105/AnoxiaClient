import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/UserVO.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key});

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _isSearching = false;
  bool _isSending = false;
  UserVO? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchService = ref.watch(userSearchServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加朋友'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索用户名或昵称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // 清空搜索结果
                          ref.read(userSearchServiceProvider.notifier).state = 
                            ref.read(userSearchServiceProvider.notifier).build();
                          _selectedUser = null;
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),

          // 搜索按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isSearching 
                  ? null 
                  : () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('搜索'),
            ),
          ),

          // 搜索结果
          Expanded(
            child: searchService.rows.isNotEmpty
                ? ListView.builder(
                    itemCount: searchService.rows.length,
                    itemBuilder: (context, index) {
                      final user = searchService.rows[index];
                      return ListTile(
                        leading: AvatarWidget(
                          url: user.avatar,
                          name: user.nickName,
                          size: 48,
                        ),
                        title: Text(user.nickName),
                        subtitle: Text('用户名: ${user.userName}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedUser = user;
                            });
                            _showAddFriendDialog(user);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('添加'),
                        ),
                      );
                    },
                  )
                : _searchController.text.isNotEmpty
                    ? const Center(
                        child: Text('未找到相关用户'),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedUserAdd02,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('搜索用户添加为朋友'),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// 执行搜索
  void _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await ref.read(userSearchServiceProvider.notifier).searchUsers(keyword);
      _selectedUser = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('搜索失败，请重试')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 显示添加朋友对话框
  void _showAddFriendDialog(UserVO user) {
    _remarkController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              AvatarWidget(
                url: user.avatar,
                name: user.nickName,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(user.nickName),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('用户名: ${user.userName}'),
              if (user.phonenumber != null)
                Text('手机号: ${user.phonenumber}'),
              const SizedBox(height: 16),
              TextField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  hintText: '请输入验证信息',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _isSending
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _sendFriendRequest(user);
                    },
              child: _isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('发送'),
            ),
          ],
        );
      },
    );
  }

  /// 发送好友申请
  Future<void> _sendFriendRequest(UserVO user) async {
    setState(() {
      _isSending = true;
    });

    try {
      final success = await ref
          .read(userSearchServiceProvider.notifier)
          .sendContactRequest(user.userId, _remarkController.text);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友申请已发送')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申请失败，可能是已经是好友或已发送过申请')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发送失败，请重试')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}
