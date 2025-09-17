import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/features/setting/presentation/controller/SettingsController.dart';
import 'package:notepadclient/features/setting/presentation/widgets/SettingItemCard.dart';

final SettingsController settingsController = getIt<SettingsController>();

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("settings_page_title".tr())),
      body: ListView(
        children: [
          SettingItemCard(),
          DropdownButton<Locale>(
            value: context.locale,
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text("English")),
              DropdownMenuItem(value: Locale('zh'), child: Text("中文")),
              DropdownMenuItem(value: Locale('ja'), child: Text("日本語")),
            ],
            onChanged: (locale) {
              if (locale != null) {
                context.setLocale(locale);
              }
            },
          ),
        ],
      ),
    );
  }
}
