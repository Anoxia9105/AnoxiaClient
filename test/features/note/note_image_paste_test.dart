import 'dart:typed_data';

import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/features/note/presentation/widgets/note_quill_actions.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionService extends NoteSessionService {
  _FakeSessionService(this._session);
  final NoteEditSession _session;

  @override
  NoteEditSession? build() => _session;
}

class _FakeUploadRepository implements UploadRepository {
  final List<String> completedIds = [];

  @override
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
    UploadCompletedCallback? onCompleted,
    int? noteId,
  }) async {
    final results = <UploadFileResult>[];
    for (final id in clientFileIds) {
      final result = UploadFileResult(
        clientFileId: id,
        isSuccess: true,
        url: 'https://example.test/img.png',
      );
      results.add(result);
      onCompleted?.call(result);
      completedIds.add(id);
    }
    return results;
  }

  @override
  void cancelUpload(String clientFileId) {}
}

void main() {
  testWidgets('剪贴板粘贴图片会插入占位并上传后替换为真实 URL', (tester) async {
    const session = NoteEditSession(
      noteId: 1,
      folderId: null,
      title: 'test',
      content: '[{"insert":"hello\\n"}]',
      plainText: 'hello\n',
      dirty: false,
      saveState: NoteSaveState.saved,
      lastSavedAt: null,
    );

    final uploadRepo = _FakeUploadRepository();
    final container = ProviderContainer(
      overrides: [
        noteSessionServiceProvider.overrideWith(
          () => _FakeSessionService(session),
        ),
        uploadRepositoryProvider.overrideWithValue(uploadRepo),
      ],
    );
    addTearDown(container.dispose);

    final controller = QuillController(
      document: Document()..insert(0, 'hello\n'),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);

    late WidgetRef widgetRef;
    late BuildContext hostContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              hostContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    controller.updateSelection(
      TextSelection.collapsed(offset: controller.document.length - 1),
      ChangeSource.local,
    );

    // 模拟从剪贴板粘贴图片字节
    final bytes = Uint8List.fromList(List<int>.filled(16, 0x89));
    await notePasteImageBytes(hostContext, widgetRef, controller, bytes);

    // 走查 delta：应有 image 嵌入占位
    final imageOps = controller.document.toDelta().toList().where((op) {
      final data = op.data;
      return data is Map && data[BlockEmbed.imageType] != null;
    }).toList();
    expect(imageOps, hasLength(1), reason: '粘贴后应插入一个图片嵌入');
    expect(uploadRepo.completedIds, hasLength(1));

    // 上传完成（onCompleted 同步触发）后占位被替换为真实 URL
    final embedMap = imageOps.first.data! as Map;
    expect(
      embedMap[BlockEmbed.imageType] as String,
      contains('https://example.test/img.png'),
    );
  });
}
