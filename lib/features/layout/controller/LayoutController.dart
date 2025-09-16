import 'package:flutter/cupertino.dart';

/// 布局控制器
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:16
class LayoutController extends ChangeNotifier{
  int currentIndex=0;

  void changeIndex(int index){
    currentIndex=index;
    notifyListeners();
  }


  ///MAX | MIN
  ///最大最小化 图标切换
  bool _extended = false;
  bool get extended => _extended;
  set extendedValue(bool value) {
    _extended = value;
    notifyListeners();
  }



}