import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:notepadclient/core/domain/RoomSummary.dart';
import 'package:notepadclient/core/domain/SysUser.dart';
import 'package:notepadclient/core/network/IMClient.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/features/chat/service/IChatService.dart';

import '../../../core/di/injector.dart';

class ChatController extends ChangeNotifier {
  ///依赖注入
  late IMClient _imClient;
  final IChatService _chatService=getIt<IChatService>();
  // final SysUser? _user=getIt<AuthController>().userInfo;

  //RoomSummary
  List<RoomSummary> roomSummaryList=[];

  void bindClient(IMClient client) {
    _imClient = client;
    // 全局订阅（也可以按 topic 订阅）
    final subAll = _imClient.subscribeAll((msg) {
      print('收到消息: $msg');
    });
  }

  ///ListView 控制器 左侧列表
  final ScrollController scrollChatListController = ScrollController();

  ChatController() {
    scrollChatListController.addListener(_onScroll);
  }


  final FlutterListViewController listViewController = FlutterListViewController();

  ///是否滚动
  bool _isScrolling = false;

  ///滚动延时计时器
  /// 滚动结束后才Hover ListTile颜色 优化
  Timer? _scrollStopTimer;

  bool get isScrolling => _isScrolling;

  void _onScroll() {
    if (!_isScrolling) {
      _isScrolling = true;
      notifyListeners();
    }

    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(milliseconds: 500), () {
      _isScrolling = false;
      notifyListeners();
    });
  }

  ///ListTile选择索引
  /// 选择切换 ChatDetail
  int _selectedIndex = -1;

  get selectIndex => _selectedIndex;

  ///切换左侧列表索引
  /// 选择切换 ChatDetail
  void setSelectIndex(int index) {
    _selectedIndex = index;
    // setChatRoom = getRoom(index);
    // String? roomId= roomSummaryList[index]?.roomId;
    // if(roomId != null && _user !=null && _user.data != null){
    //  num userId= _user.data?.userId ?? 0;
    //  _chatService.getRoomMessage(roomId,userId);
    // }
    notifyListeners();
  }
}
