import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/app_background_repository_impl.dart';
import '../../../domain/repositories/app_background_repository.dart';
import '../../network/dio_client.dart';

final appBackgroundRepositoryProvider = Provider<AppBackgroundRepository>((
  ref,
) {
  return AppBackgroundRepositoryImpl(DioClient());
});
