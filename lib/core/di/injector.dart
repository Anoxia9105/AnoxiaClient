import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/features/auth/service/IAuthService.dart';
import 'package:notepadclient/features/auth/service/impl/AuthServiceImpl.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/features/setting/controller/SettingsController.dart';

import '../network/DioClient.dart';
import '../network/DioConfig.dart';
import '../network/TokenStorage.dart';
import '../storage/SecureStorageService .dart';


final GetIt getIt = GetIt.instance;

Future<void> init() async {
  // 1. 懒加载单例（第一次用时才创建，之后复用）
  //sl.registerLazySingleton<ApiService>(() => ApiServiceImpl());

// 2. 立即创建单例（注册时就创建）
  //sl.registerSingleton<ConfigService>(ConfigService());

// 3. 工厂模式（每次获取都是新对象）
  //sl.registerFactory<LoginCubit>(() => LoginCubit(sl<ApiService>()));

  getIt.registerSingleton<LayoutController>(LayoutController());
  getIt.registerSingleton<SettingsController>(SettingsController());
  getIt.registerSingleton<AuthController>(AuthController());
  getIt.registerSingleton<ChatController>(ChatController());




  getIt.registerFactory<IAuthService>(() => AuthServiceImpl());


  // Core
  // getIt.registerSingleton<SecureStorageService>(SecureStorageService());
  // getIt.registerSingleton<TokenStorage>(TokenStorage());
  // final dio = DioConfig.createDio();
  // getIt.registerSingleton<Dio>(dio);
  // getIt.registerSingleton<DioClient>(DioClient(dio, getIt<TokenStorage>()));

  // // API
  // getIt.registerSingleton<Endpoints>(Endpoints());
  //
  // // Feature: Auth
  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //         () => AuthRemoteDataSourceImpl(getIt<DioClient>()));
  // getIt.registerLazySingleton<AuthRepository>(
  //         () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<TokenStorage>()));
  // getIt.registerFactory(() => LoginUseCase(getIt<AuthRepository>()));
}
