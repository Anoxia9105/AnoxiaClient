import 'package:anoxia/data/repositories/note_repository_impl.dart';
import 'package:anoxia/domain/repositories/note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 记事本仓库 Provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl();
});
