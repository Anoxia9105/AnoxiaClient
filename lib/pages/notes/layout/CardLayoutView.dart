import 'package:anoxia/framework/domain/NoteTreeNode.dart';
import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/widgets/NoteEditorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardLayoutView extends ConsumerStatefulWidget {
  const CardLayoutView({super.key});

  @override
  ConsumerState<CardLayoutView> createState() => _CardLayoutViewState();
}

class _CardLayoutViewState extends ConsumerState<CardLayoutView>
    with TickerProviderStateMixin {
  CardSwiperController? _swiperController;
  late TabController _tabController;
  int _currentIndex = 0;
  bool _tabChangingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
    _tabController = TabController(length: 0, vsync: this);
  }

  void _syncTabController(int length) {
    if (_tabController.length != length) {
      _tabController.dispose();
      _tabController = TabController(
        length: length,
        vsync: this,
        initialIndex: _currentIndex.clamp(0, length > 0 ? length - 1 : 0),
      );
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) return;
        if (!_tabChangingProgrammatically &&
            _tabController.index != _currentIndex) {
          _goToIndex(_tabController.index);
        }
      });
    }
  }

  void _goToIndex(int index) {
    setState(() => _currentIndex = index);
    ref.read(noteProvider.notifier).setCardIndex(index);
    _tabChangingProgrammatically = true;
    _tabController.animateTo(index);
    _tabChangingProgrammatically = false;
  }

  @override
  void dispose() {
    _swiperController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteProvider).value;
    final notes = state?.flatNotes ?? [];
    final cs = Theme.of(context).colorScheme;

    _syncTabController(notes.length);

    if (notes.isEmpty) {
      return const NoteEmptyPlaceholder();
    }

    return Column(
      children: [
        // ── Tab 栏 ──────────────────────────────────────────
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: cs.primary,
            indicatorWeight: 2,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: notes
                .map(
                  (n) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sticky_note_2_outlined, size: 14),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(n.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // ── CardSwiper ──────────────────────────────────────
        Expanded(
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: notes.length,
            initialIndex: _currentIndex.clamp(0, notes.length - 1),
            numberOfCardsDisplayed: notes.length > 2 ? 2 : 1,
            backCardOffset: const Offset(16, 12),
            scale: 0.94,
            padding: const EdgeInsets.all(16),
            onSwipe: (prev, current, direction) {
              if (current != null && current != _currentIndex) {
                setState(() => _currentIndex = current);
                _tabChangingProgrammatically = true;
                _tabController.animateTo(current);
                _tabChangingProgrammatically = false;
                ref.read(noteProvider.notifier).setCardIndex(current);
              }
              return true;
            },
            cardBuilder: (context, index, pX, pY) {
              final note = notes[index];
              return _NoteCard(note: note, isActive: index == _currentIndex);
            },
          ),
        ),

        // ── 底部翻页按钮 ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onTap: _currentIndex > 0
                    ? () => _goToIndex(_currentIndex - 1)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1} / ${notes.length}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(width: 12),
              _NavButton(
                icon: Icons.chevron_right,
                onTap: _currentIndex < notes.length - 1
                    ? () => _goToIndex(_currentIndex + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 卡片容器 ────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final NoteTreeNode note;
  final bool isActive;

  const _NoteCard({required this.note, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isActive ? 0.12 : 0.06),
            blurRadius: isActive ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: NoteEditorWidget(node: note),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: onTap != null ? cs.primaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? cs.onPrimaryContainer : cs.outline,
          ),
        ),
      ),
    );
  }
}
