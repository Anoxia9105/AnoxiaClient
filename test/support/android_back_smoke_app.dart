// Android 原生返回链路验证入口，不连接业务服务、不需要登录。
// flutter build apk --debug -t test/support/android_back_smoke_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(
    MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const _Home(),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, _) =>
                    const Scaffold(body: Center(child: Text('Detail page'))),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Android back smoke test')),
    body: Column(
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Draft')),
        TextButton(
          onPressed: () => context.push('/detail'),
          child: const Text('Open detail'),
        ),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(content: Text('Dialog content')),
          ),
          child: const Text('Open dialog'),
        ),
        TextButton(
          onPressed: () => SystemNavigator.pop(),
          child: const Text('Root back'),
        ),
        TextButton(
          onPressed: () => const MethodChannel(
            'app_navigation',
          ).invokeMethod<void>('exitApp'),
          child: const Text('Explicit exit'),
        ),
      ],
    ),
  );
}
