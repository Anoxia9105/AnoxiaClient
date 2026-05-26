import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';

class InAppCallMinWindow extends ConsumerWidget {
  const InAppCallMinWindow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // 💡 1. 修改状态机：恢复全屏状态
        ref.read(mobileCallSessionControllerProvider.notifier).enterCallPage();
        
        // 💡 2. 再次将全屏通话页面压入栈顶
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MobileCallPage(
              roomId: session.roomId,
              title: session.title,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call, color: Colors.greenAccent, size: 28),
              SizedBox(height: 4),
              Text(
                '通话中...',
                style: TextStyle(color: Colors.white, fontSize: 11, decoration: TextDecoration.none),
              )
            ],
          ),
        ),
      ),
    );
  }
}