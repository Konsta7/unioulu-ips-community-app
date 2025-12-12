import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import 'dart:developer' as developer;

class Login {
  final AuthRepository repository;

  Login(this.repository);

  Future<User> execute(String email, String password) {
    developer.log("login.dart");
    return repository.login(email, password);
  }
}
