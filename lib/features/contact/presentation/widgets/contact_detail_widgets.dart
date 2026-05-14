import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ContactDetailEmptyState extends StatelessWidget {
  const ContactDetailEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('contact_select_contact'.tr()));
  }
}

class ContactInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const ContactInfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class ContactDetailSkeleton extends StatelessWidget {
  const ContactDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 24),
          SkeletonBox(width: 100, height: 100, radius: 12),
          SizedBox(height: 16),
          SkeletonBox(width: 140, height: 22),
          SizedBox(height: 28),
          Divider(),
          _ContactInfoSkeletonLine(),
          _ContactInfoSkeletonLine(),
          _ContactInfoSkeletonLine(),
          _ContactInfoSkeletonLine(),
          _ContactInfoSkeletonLine(),
          SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: SkeletonBox(height: 48, radius: 10),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ContactInfoSkeletonLine extends StatelessWidget {
  const _ContactInfoSkeletonLine();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 32),
      title: Row(
        children: [
          SkeletonBox(width: 70, height: 12),
          SizedBox(width: 16),
          Expanded(child: SkeletonBox(height: 12)),
        ],
      ),
    );
  }
}
