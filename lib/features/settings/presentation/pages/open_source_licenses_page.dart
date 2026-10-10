import 'package:anoxia/oss_licenses.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 开源许可证页面
///
/// 展示项目所使用的开源依赖库列表及其许可证信息，
/// 支持点击查看详细许可证文本。

/// 开源许可证列表页面
///
/// 列出所有已声明的开源依赖，按名称排序，每个条目显示版本号、
/// SPDX 标识和简要描述，点击可查看完整许可证文本。
class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 注意：这里只读 name/version/description，绝不触碰 pkg.license。
    // license 全文平均 2~16KB、总计约 700KB，列表行持有它会让整页
    // 常驻大字符串；全文只在详情页打开单个包时才读取。
    final packages =
        allDependencies
            .where((p) => (p.license ?? '').trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return AppScaffold(
      hideAppBarLogo: true,
      showWebNavigationBar: true,
      showMobileNavigationBar: true,
      title: Text('settings_open_source_title'.tr()),
      body: packages.isEmpty
          ? Center(child: Text('settings_open_source_empty'.tr()))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: packages.length,
              // 关键优化（Windows 实测大头）：
              // - 关闭 AutomaticKeepAlives：滑出视口的行直接销毁，不驻留
              //   Element/RenderObject（默认开启时 300+ 行常驻很贵）。
              // - 限制 cacheExtent：预渲染区只保留一屏左右，不提前光栅化全表。
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              cacheExtent: 320,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final pkg = packages[index];
                final version = (pkg.version ?? '').trim();
                final description = (pkg.description).trim();

                // 用 Card.outlined（elevation=0）替代默认 Card：
                // 默认 Card 带阴影，每行都要进 raster cache 做阴影模糊，
                // 300 行滚动时 Windows 上光栅缓存暴涨；outlined 无阴影，
                // 只有 1px 边框，开销可忽略。
                // 再包一层 RepaintBoundary，避免滚动时整表重绘。
                return RepaintBoundary(
                  child: Card.outlined(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: () {
                        OpenSourceLicenseDetailRoute(
                          packageName: pkg.name,
                        ).push(context);
                      },
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pkg.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (version.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(RadiusToken.md),
                              ),
                              child: Text(
                                version,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: description.isNotEmpty
                          ? Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 开源许可证详情页面
///
/// 显示指定依赖包的完整许可证文本，包含版本号和 SPDX 标识信息。
class OpenSourceLicenseDetailPage extends StatelessWidget {
  /// 包名称
  final String packageName;

  const OpenSourceLicenseDetailPage({super.key, required this.packageName});

  Package? _findPackage() {
    for (final item in allDependencies) {
      if (item.name == packageName) {
        return item;
      }
    }
    return null;
  }

  /// 把超长许可证按行切块，避免单个巨型 RenderParagraph。
  ///
  /// 原写法是 ListView > SingleChildScrollView > SelectableText(全文)：
  /// 内层 scroll 在外层 ListView 的无界高度里会展开成全文高度
  /// （MPL 约 16KB / 300+ 行 / 8000px+），Skia 要把它光栅化成一张
  /// 巨型 picture（宽×高×4字节×DPR²），Windows 上轻松吃掉几百 MB，
  /// 这就是 400M -> 900M 飙升的主因。
  /// 切成 100 行一块 + SliverList.builder 懒加载后，视口外不排版、
  /// 不光栅化，峰值只剩一两块。
  static List<String> _chunkLicenseText(String text) {
    const linesPerChunk = 100;
    final lines = text.split('\n');
    if (lines.length <= linesPerChunk) return <String>[text];
    final chunks = <String>[];
    for (var i = 0; i < lines.length; i += linesPerChunk) {
      final end = (i + linesPerChunk < lines.length)
          ? i + linesPerChunk
          : lines.length;
      chunks.add(lines.sublist(i, end).join('\n'));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final package = _findPackage();
    if (package == null) {
      return Scaffold(
        appBar: AppBar(title: Text(packageName)),
        body: Center(
          child: Text('settings_open_source_package_not_found'.tr()),
        ),
      );
    }

    final version = (package.version ?? '').trim();
    final title = package.name;
    final fullText = (package.license ?? '').trim().isEmpty
        ? 'settings_open_source_no_license_text'.tr()
        : package.license!;
    final chunks = _chunkLicenseText(fullText);
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.5);

    // 单一 CustomScrollView：之前 ListView 套 SingleChildScrollView 是
    // 嵌套滚动，手势冲突 + 双重 Scrollbar + 全文一次性 layout。
    // 现在只有一个纵向滚动体，license 分块懒加载。
    return AppScaffold(
      hideAppBarLogo: true,
      showWebNavigationBar: true,
      showMobileNavigationBar: true,
      title: Text(title),
      body: CustomScrollView(
        cacheExtent: 600,
        slivers: [
          if (version.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Card.outlined(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingToken.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'settings_open_source_version'.tr(
                              args: [version],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).copyButtonLabel,
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: fullText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('chat_copy_success'.tr()),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList.builder(
              itemCount: chunks.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
              itemBuilder: (context, index) {
                // 每块独立 RepaintBoundary：滚动时只重绘可见块，
                // 巨型 license 不会合并成一张大图。
                return RepaintBoundary(
                  child: Card.outlined(
                    margin: EdgeInsets.only(
                      bottom: index == chunks.length - 1 ? 0 : 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingToken.md),
                      child: SelectableText(chunks[index], style: bodyStyle),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
