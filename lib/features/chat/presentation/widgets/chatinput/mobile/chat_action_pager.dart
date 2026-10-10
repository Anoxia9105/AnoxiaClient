import 'package:flutter/material.dart';

/// 每页固定四列两排；新增操作自动进入下一页。
class ChatActionPager extends StatefulWidget {
  final List<Widget> actions;
  const ChatActionPager({super.key, required this.actions});

  @override
  State<ChatActionPager> createState() => _ChatActionPagerState();
}

class _ChatActionPagerState extends State<ChatActionPager> {
  final _controller = PageController();
  int _page = 0;

  @override
  void didUpdateWidget(covariant ChatActionPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pages = (widget.actions.length / 8).ceil();
    if (_page >= pages) {
      _page = pages > 0 ? pages - 1 : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(_page);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = (widget.actions.length / 8).ceil();
    if (pages == 0) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: pages,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, page) => LayoutBuilder(
              builder: (context, size) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: (size.maxHeight - 32) / 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: (widget.actions.length - page * 8).clamp(0, 8),
                  itemBuilder: (_, index) => widget.actions[page * 8 + index],
                );
              },
            ),
          ),
        ),
        if (pages > 1)
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages,
                (index) => Semantics(
                  label: '${index + 1} / $pages',
                  selected: index == _page,
                  button: true,
                  child: InkWell(
                    onTap: () => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 8,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _page ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
