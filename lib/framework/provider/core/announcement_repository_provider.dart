import 'package:anoxia/data/repositories/announcement_repository_impl.dart';
import 'package:anoxia/domain/repositories/announcement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(),
);
