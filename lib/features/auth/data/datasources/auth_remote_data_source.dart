import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite;
import 'package:get_it/get_it.dart';

import '../../../../core/services/http_appwrite_service.dart';

class AuthRemoteDataSource {
  final Account account;

  AuthRemoteDataSource(this.account);

  /// Registers a new user with the given email, password, and name.
  /// Automatically assigns a "student" label to the new user.
  Future<appwrite.User> register(
      String email, String password, String name) async {
    try {
      // Create a new user account
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Access the registered AppwriteService instance
      final appwriteService = GetIt.instance<AppwriteService>();
      final response = await appwriteService.makeRequest(
        method: 'PUT',
        endpointPath: 'users/${user.$id}/labels', // Endpoint path
        data: {
          'labels': ['user']
        }, // Data to send
      );

      // Handle response dynamically
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to set default user label: ${response.body}');
      }

      return user;
    } catch (e) {
      // Handle any exceptions that occur during user creation or label assignment
      developer.log('Error during user registration: $e');
      rethrow;
    }
  }

  Future<appwrite.Session> login(String email, String password) async {
    return await account.createEmailPasswordSession(
        email: email, password: password);
  }

  Future<void> logout() async {
    return await account.deleteSession(sessionId: 'current');
  }

  Future<appwrite.Session> authenticateAnonymous() async {
    return await account.createAnonymousSession();
  }

  Future<appwrite.User> updateProfile(String name) async {
    return await account.updateName(name: name);
  }

//TODO: Implement the resetPassword method
  Future<appwrite.Token> resetPassword(String email) async {
    return await account.createRecovery(
        email: email, url: 'https://example.com');
  }

  Future<appwrite.Token> createVerification({required String url}) async {
    try {
      return await account.createVerification(url: url);
    } catch (e) {
      developer.log('Error creating verification: $e');
      rethrow;
    }
  }

  Future<appwrite.User> getUser() async {
    return await account.get();
  }
}
