import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 设置页左侧导航项及其对应详情面板。
class SettingsDestination {
  const SettingsDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final WidgetBuilder builder;
}

/// 与聊天页一致的主从式布局：宽屏左侧列表、右侧详情，窄屏进入详情页。
class SettingsSplitView extends StatefulWidget {
  const SettingsSplitView({
    super.key,
    required this.destinations,
    this.compactBreakpoint = 700,
  }) : assert(destinations.length > 0);

  final List<SettingsDestination> destinations;
  final double compactBreakpoint;

  @override
  State<SettingsSplitView> createState() => _SettingsSplitViewState();
}

class _SettingsSplitViewState extends State<SettingsSplitView> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant SettingsSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.destinations.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.compactBreakpoint) {
          return _SettingsNavigationList(
            destinations: widget.destinations,
            onSelected: (index) => _openCompactDetail(context, index),
          );
        }

        final compactDesktop = constraints.maxWidth < 1000;

        return Row(
          children: [
            SizedBox(
              width: compactDesktop ? 240 : 300,
              child: _SettingsNavigationList(
                destinations: widget.destinations,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RadiusToken.xl),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        for (var i = 0; i < widget.destinations.length; i++)
                          TickerMode(
                            enabled: i == _selectedIndex,
                            child: RepaintBoundary(
                              child: _SettingsDetailPanel(
                                key: ValueKey(i),
                                destination: widget.destinations[i],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCompactDetail(BuildContext context, int index) {
    final destination = widget.destinations[index];
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(title: Text(destination.title)),
            body: _SettingsDetailPanel(destination: destination, compact: true),
          );
        },
      ),
    );
  }
}

class _SettingsNavigationList extends StatelessWidget {
  const _SettingsNavigationList({
    required this.destinations,
    required this.onSelected,
    this.selectedIndex,
  });

  final List<SettingsDestination> destinations;
  final ValueChanged<int> onSelected;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      key: const Key('settings-navigation-list'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      itemCount: destinations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final destination = destinations[index];
        final selected = selectedIndex == index;

        return Material(
          color: selected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          child: ListTile(
            key: Key('settings-navigation-item-$index'),
            minTileHeight: 52,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            horizontalTitleGap: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
            selected: selected,
            leading: HugeIcon(
              icon: destination.icon,
              size: 20,
              color: selected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              destination.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: selectedIndex == null
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 18,
                    color: colorScheme.outline,
                  )
                : null,
            onTap: () => onSelected(index),
          ),
        );
      },
    );
  }
}

class _SettingsDetailPanel extends StatelessWidget {
  const _SettingsDetailPanel({
    super.key,
    required this.destination,
    this.compact = false,
  });

  final SettingsDestination destination;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: compact
            ? colorScheme.surface
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(compact ? 0 : 14),
        border: compact
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.18),
              ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              compact ? 20 : 24,
              compact ? 16 : 24,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: destination.icon,
                        size: 30,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destination.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              0,
              compact ? 12 : 20,
              24,
            ),
            sliver: SliverToBoxAdapter(child: destination.builder(context)),
          ),
        ],
      ),
    );
  }
}
