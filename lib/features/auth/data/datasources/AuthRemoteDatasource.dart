import 'package:dio/dio.dart';
import '../../../../api/Endpoints.dart';
import '../../../../core/network/DioClient.dart';
import '../models/UserModel.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;
  final Endpoints endpoints = Endpoints();

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await client.post(endpoints.login, data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['data']);
  }
}
