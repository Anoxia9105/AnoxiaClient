

import '../../../../core/network/TokenStorage.dart';
import '../../domain/entities/User.dart';
import '../../domain/repositories/AuthRepository.dart';
import '../datasources/AuthRemoteDatasource.dart';
import '../models/UserModel.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl(this.remote, this.tokenStorage);

  @override
  Future<User> login(String email, String password) async {





    final userModel = await remote.login(email, password);
    await tokenStorage.saveAccessToken(userModel.token);
    return User(id: userModel.id, email: userModel.email, name: userModel.name);
  }
}
