import 'package:flutter/material.dart';

/// 当前聊天页面只保留一条消息的选区，不在进程内保存气泡 State。
class MessageSelectionScope extends StatefulWidget {
  const MessageSelectionScope({super.key, required this.child});
  final Widget child;

  static MessageSelectionScopeState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectionScope>()?.state;

  @override
  State<MessageSelectionScope> createState() => MessageSelectionScopeState();
}

class MessageSelectionScopeState extends State<MessageSelectionScope> {
  MessageSelectionHandle? _active;
  int? _messagePointer;

  void claim(MessageSelectionHandle handle, {int? pointer}) {
    _messagePointer = pointer;
    if (identical(_active, handle)) return;
    final previous = _active;
    _active = handle;
    previous?.clear();
  }

  void release(MessageSelectionHandle handle) {
    if (identical(_active, handle)) _active = null;
  }

  @override
  Widget build(BuildContext context) => _SelectionScope(
    state: this,
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // 消息子节点先收到原始事件；空白、输入框、头像等不认领事件，退出选区。
        if (_messagePointer == event.pointer) return;
        final previous = _active;
        _active = null;
        previous?.clear();
      },
      child: widget.child,
    ),
  );
}

class _SelectionScope extends InheritedWidget {
  const _SelectionScope({required this.state, required super.child});
  final MessageSelectionScopeState state;
  @override
  bool updateShouldNotify(_SelectionScope oldWidget) =>
      state != oldWidget.state;
}

/// 菜单与消息渲染器之间的局部桥梁。文档/选区仍由各渲染器持有。
class MessageSelectionHandle extends ChangeNotifier {
  bool selecting = false;
  VoidCallback? selectAll;
  VoidCallback? clearSelection;
  String? Function()? selectedText;
  ValueChanged<Offset>? showMenu;
  MessageSelectionScopeState? _scope;

  void activate(MessageSelectionScopeState? scope, {int? pointer}) {
    if (_scope != scope) _scope?.release(this);
    _scope = scope;
    scope?.claim(this, pointer: pointer);
  }

  void begin() {
    selecting = true;
    notifyListeners();
    // 先让只读渲染器开放触摸选择，再建立选区和手柄。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selecting) selectAll?.call();
    });
  }

  void clear() {
    final wasSelecting = selecting;
    selecting = false;
    clearSelection?.call();
    if (wasSelecting) notifyListeners();
  }

  @override
  void dispose() {
    selecting = false;
    _scope?.release(this);
    selectAll = null;
    clearSelection = null;
    selectedText = null;
    showMenu = null;
    super.dispose();
  }
}

class MessageSelectionTarget extends InheritedNotifier<MessageSelectionHandle> {
  const MessageSelectionTarget({
    super.key,
    required MessageSelectionHandle handle,
    required super.child,
  }) : super(notifier: handle);

  static MessageSelectionHandle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MessageSelectionTarget>()
      ?.notifier;
}
