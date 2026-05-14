import 'package:anoxia/oss_licenses.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('开源许可')),
      body: ListView.separated(
        itemCount: packages.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pkg = packages[index];
          final version = (pkg.version ?? '').trim();
          final spdx = pkg.spdxIdentifiers.join(' / ');

          return ListTile(
            title: Text(version.isEmpty ? pkg.name : '${pkg.name}  $version'),
            subtitle: Text(
              spdx.isNotEmpty ? spdx : (pkg.description),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _LicenseDetailPage(package: pkg),
                ),
              );
            },
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
    final title = version.isEmpty ? package.name : '${package.name}  $version';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.spdxIdentifiers.isNotEmpty) ...[
              Text(
                'License: ${package.spdxIdentifiers.join(' / ')}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: .6),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    package.license ?? 'No license text provided.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
