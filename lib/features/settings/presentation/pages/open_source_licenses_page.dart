import 'package:anoxia/oss_licenses.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packages =
        allDependencies
            .where((p) => (p.license ?? '').trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final canGoBack = context.canPop();

    return AppScaffold(
      title: 'settings_open_source_title',
      body: Column(
        children: [
          if (canGoBack)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('common_back'.tr()),
                ),
              ),
            ),
          Expanded(
            child: packages.isEmpty
                ? Center(child: Text('settings_open_source_empty'.tr()))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      final version = (pkg.version ?? '').trim();
                      final spdx = pkg.spdxIdentifiers.join(' / ').trim();
                      final description = (pkg.description).trim();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            OpenSourceLicenseDetailRoute(packageName: pkg.name)
                                .push(context);
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                const SizedBox(height: 8),
                                Text(
                                  spdx.isNotEmpty
                                      ? spdx
                                      : 'settings_open_source_license_unlabeled'
                                            .tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.chevron_right_rounded,
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
          ),
        ],
      ),
    );
  }
}

class OpenSourceLicenseDetailPage extends StatelessWidget {
  final String packageName;

  const OpenSourceLicenseDetailPage({
    super.key,
    required this.packageName,
  });

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
        body: Center(child: Text('settings_open_source_package_not_found'.tr())),
      );
    }

    final version = (package.version ?? '').trim();
    final spdx = package.spdxIdentifiers.join(' / ').trim();
    final title = package.name;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (version.isNotEmpty)
                    Text(
                      'settings_open_source_version'.tr(args: [version]),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (version.isNotEmpty && spdx.isNotEmpty)
                    const SizedBox(height: 6),
                  if (spdx.isNotEmpty)
                    Text(
                      'settings_open_source_spdx'.tr(args: [spdx]),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
