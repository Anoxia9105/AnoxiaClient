import 'package:anoxia/oss_licenses.dart';
import 'package:anoxia/pages/AppScaffold.dart';
import 'package:flutter/material.dart';

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
      title: '开源许可',
      body: packages.isEmpty
          ? const Center(child: Text('暂无可显示的许可证信息'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _LicenseDetailPage(package: pkg),
                        ),
                      );
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
                                    borderRadius: BorderRadius.circular(8),
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
                            spdx.isNotEmpty ? spdx : 'License 未标注',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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
    );
  }
}

class _LicenseDetailPage extends StatelessWidget {
  final Package package;

  const _LicenseDetailPage({required this.package});

  @override
  Widget build(BuildContext context) {
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
                      '版本：$version',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (version.isNotEmpty && spdx.isNotEmpty)
                    const SizedBox(height: 6),
                  if (spdx.isNotEmpty)
                    Text(
                      '许可证：$spdx',
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
                          ? 'No license text provided.'
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
