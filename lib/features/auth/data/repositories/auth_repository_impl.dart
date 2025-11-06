import 'package:isar/isar.dart';
import 'package:appwrite/models.dart' as appwrite;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
import 'dart:developer' as developer;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final Isar isar;

  AuthRepositoryImpl(this.remoteDataSource, this.isar);

  @override
  Future<User> register(String email, String password, String name) async {
    developer.log('Starting registration for email: $email');
    final appwrite.User user =
        await remoteDataSource.register(email, password, name);

    // Send verification email right after registration
    /*
    try {
      await remoteDataSource.createVerification(
          url:
              'http://localhost:8080/verify-email' // Replace with your actual domain
          );
    } catch (e) {
      // Log the error but don't fail registration
      throw Exception('Failed to get current user: ${e.toString()}');
    }
    */

    final userModel = UserModel.fromAppwriteUser(user);
    await isar.writeTxn(() async {
      await isar.userModels.clear();
      await isar.userModels.put(userModel);
    });
    return userModel.toEntity();
  }

  Future<void> confirmVerification(String userId, String secret) async {
    try {
      await remoteDataSource.updateVerification(
        userId: userId,
        secret: secret,
      );
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<User> login(String email, String password) async {
    await remoteDataSource.login(email, password);
    final appwrite.User user = await remoteDataSource.getUser();
    final userModel = UserModel.fromAppwriteUser(user);
    await isar.writeTxn(() async {
      await isar.userModels.clear();
      await isar.userModels.put(userModel);
    });
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await isar.writeTxn(() async {
      await isar.userModels.clear();
    });
  }

  @override
  Future<User> authenticateAnonymous() async {
    final appwrite.User user = await remoteDataSource.getUser();
    final userModel = UserModel.fromAppwriteUser(user);
    await isar.writeTxn(() async {
      await isar.userModels.clear();
      await isar.userModels.put(userModel);
    });
    return userModel.toEntity();
  }

  @override
  Future<User> updateProfile(String name) async {
    final appwrite.User user = await remoteDataSource.updateProfile(name);
    final userModel = UserModel.fromAppwriteUser(user);
    await isar.writeTxn(() async {
      await isar.userModels.put(userModel);
    });
    return userModel.toEntity();
  }

  @override
  Future<void> resetPassword(String email) {
    return remoteDataSource.resetPassword(email);
  }

  @override
  Future<String> getCurrentUserId() async {
    try {
      final user = await remoteDataSource.getUser();
      return user.$id;
    } catch (e) {
      throw Exception('Failed to get current user ID: ${e.toString()}');
    }
  }

  Future<String> getCurrentUserName() async {
    try {
      final user = await remoteDataSource.getUser();
      return user.name;
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }
}
