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
    developer.log("Account registered successfully");

    try {
      // Login right after registration to send verification email
      developer.log("Logging in to send verification email");
      await remoteDataSource.login(email, password);

      // Create verification link - use the physical device's reachable IP
      developer.log("Creating verification email with deep link");
      await remoteDataSource.createVerification(
          url: 'http://localhost:8081/verify-email.html');

      // Logout after sending verification so user must login again to proceed
      developer.log("Logging out after sending verification");
      await remoteDataSource.logout();
    } catch (e) {
      developer.log('Error during registration verification setup: $e');
      // Don't fail registration if verification setup fails - user can still login
    }

    // Save user with emailVerified = false (not yet verified)
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
    developer.log("Phase 1");
    await remoteDataSource.login(email, password);
    developer.log("Phase 2");
    final appwrite.User user = await remoteDataSource.getUser();
    if (user.emailVerification == false) {
      remoteDataSource.logout();

      throw Exception('Email not verified');
    } else {
      developer.log("Phase 3");
      final userModel = UserModel.fromAppwriteUser(user);
      developer.log("Phase 4");
      await isar.writeTxn(() async {
        developer.log("Phase 5");
        await isar.userModels.clear();
        developer.log("Phase 6");
        await isar.userModels.put(userModel);
      });
      return userModel.toEntity();
    }
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
