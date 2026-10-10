import 'package:anoxia/oss_licenses.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index];
                final version = (pkg.version ?? '').trim();
                final description = (pkg.description).trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(RadiusToken.lg),
                    onTap: () {
                      OpenSourceLicenseDetailRoute(
                        packageName: pkg.name,
                      ).push(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  pkg.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (version.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
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
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: SpacingToken.sm),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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

    return AppScaffold(
      hideAppBarLogo: true,
      showWebNavigationBar: true,
      showMobileNavigationBar: true,
      title: Text(title),
      body: ListView(
        padding: const EdgeInsets.all(SpacingToken.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SpacingToken.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (version.isNotEmpty)
                    Text(
                      'settings_open_source_version'.tr(args: [version]),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SpacingToken.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 260),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      (package.license ?? '').trim().isEmpty
                          ? 'settings_open_source_no_license_text'.tr()
                          : package.license!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
