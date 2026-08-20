import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_open_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/note_editor.dart';
import '../widgets/note_tree_panel.dart';

/// 记事本页面
///
/// - 桌面端：左侧树面板 + 右侧编辑器（主从布局），编辑器区域按
///   设置中的桌面布局偏好以卡片包裹（平铺模式去掉卡片，与聊天一致）
/// - 移动端：树列表页，点击笔记 push 全屏编辑器
class NotesPage extends ConsumerStatefulWidget {
  /// 深链打开指定笔记（来自分享卡片等场景）
  final int? initialNoteId;

  const NotesPage({super.key, this.initialNoteId});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  int? _selectedNoteId;

  /// 正在打开中的笔记 ID：同步置位，防止连点/双击同一笔记重复 push 编辑页
  int? _openingNoteId;

  @override
  void initState() {
    super.initState();
    // 进入记事本页即静默刷新树：移动端每次 push 都会重新走 initState；
    // 桌面端常驻 IndexedStack 只走一次，由下方布局监听负责切页签时刷新。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteTreeServiceProvider.notifier).refresh(quiet: true);
    });
    final initial = widget.initialNoteId;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openNoteById(initial);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 当前打开的笔记被删除（或移出树）时，关闭会话并清除选中
    ref.listen(noteTreeServiceProvider, (previous, next) {
      final selected = _selectedNoteId;
      if (selected == null) return;
      final tree = next.value;
      if (tree != null && tree.findNote(selected) == null) {
        ref.read(noteSessionServiceProvider.notifier).close();
        if (mounted) setState(() => _selectedNoteId = null);
      }
    });

    // 跨页面打开请求（聊天卡片「打开笔记」等外部入口）
    ref.listen<int?>(noteOpenRequestProvider, (previous, next) {
      if (next == null) return;
      _openNoteById(next).whenComplete(() {
        // 完成后复位，允许再次请求同一笔记
        if (mounted) {
          ref.read(noteOpenRequestProvider.notifier).state = null;
        }
      });
    });

    // 桌面端常驻 IndexedStack：切到记事本页签时静默刷新树，
    // 保证换账号 / 他端修改后进入即见最新数据。
    ref.listen(layoutControllerProvider, (previous, next) {
      final noteIndex = next.items.indexWhere(
        (item) => item.name == 'sidebar_note',
      );
      if (noteIndex != -1 && next.currentIndex == noteIndex) {
        ref.read(noteTreeServiceProvider.notifier).refresh(quiet: true);
      }
    });

    final mobile = DeviceUtil.isMobile(context);

    // 标题由树面板的 AppBar 提供（与聊天/人员/收藏页一致）：
    // 桌面端靠左显示在树面板栏内，移动端整页居中显示。
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: mobile
          ? NoteTreePanel(
              selectedNoteId: null,
              onOpenNote: _openNote,
            )
          : _buildDesktop(context),
    );
  }

  /// 桌面端主从布局：树面板 + 编辑器（按布局偏好以卡片包裹编辑器）
  Widget _buildDesktop(BuildContext context) {
    final supportsDesktopLayout = DeviceUtil.supportsDesktopLayoutPreference(
      context,
    );
    final preference = ref.watch(desktopLayoutProvider);
    final style = supportsDesktopLayout
        ? resolveDesktopLayoutStyle(
            preference,
            availableWidth: MediaQuery.sizeOf(context).width,
          )
        : DesktopLayoutStyle.card;
    final isFlat = style == DesktopLayoutStyle.flat;
    final colorScheme = Theme.of(context).colorScheme;

    final editor = Expanded(
      child: isFlat
          ? const NoteEditor()
          : Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: .18),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const NoteEditor(),
                ),
              ),
            ),
    );

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: NoteTreePanel(
            selectedNoteId: _selectedNoteId,
            onOpenNote: _openNote,
          ),
        ),
        const SizedBox(width: 12),
        editor,
      ],
    );
  }

  Future<void> _openNote(NoteBrief brief) async {
    await _openNoteById(brief.id);
  }

  Future<void> _openNoteById(int noteId) async {
    // 连点保护：上一次打开尚未完成（含编辑页未返回）时忽略后续点击
    if (_openingNoteId != null) return;
    _openingNoteId = noteId;
    try {
      // 切换前先把上一个会话的未保存内容落库，避免切换丢失
      await ref.read(noteSessionServiceProvider.notifier).save();
      if (!mounted) return;

      final doc = await ref
          .read(noteTreeServiceProvider.notifier)
          .openNote(noteId);
      if (!mounted) return;
      if (DeviceUtil.isMobile(context)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NoteEditorPage(),
          ),
        );
      } else {
        setState(() => _selectedNoteId = doc.id);
      }
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_open_failed'.tr(), type: ToastType.error);
    } finally {
      _openingNoteId = null;
    }
  }
}

/// 移动端全屏笔记编辑器页
class NoteEditorPage extends ConsumerWidget {
  const NoteEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('sidebar_note'.tr()),
      ),
      body: const NoteEditor(),
    );
  }
}