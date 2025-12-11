import 'package:isar/isar.dart';
import 'package:appwrite/models.dart' as appwrite;
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@Collection()
class UserModel {
  Id id = Isar.autoIncrement;
  late String userId;
  late String email;
  late String name;
  late String labels;
  late bool emailVerified;

  UserModel(
      {required this.userId,
      required this.email,
      required this.name,
      required this.labels,
      this.emailVerified = false});

  factory UserModel.fromAppwriteUser(appwrite.User user) {
    return UserModel(
      userId: user.$id,
      email: user.email,
      name: user.name,
      labels: user.labels.join(','),
      emailVerified: user.emailVerification,
    );
  }

  appwrite.User toAppwriteUser() {
    return appwrite.User(
      $id: userId,
      $createdAt: '', // Assign default or current date if needed
      $updatedAt: '', // Assign default or current date if needed
      name: name,
      password: null,
      hash: null,
      hashOptions: null,
      registration: '',
      status: false,
      labels: labels.split(','),
      passwordUpdate: '',
      email: email,
      phone: '',
      emailVerification: false,
      phoneVerification: false,
      mfa: false,
      prefs: appwrite.Preferences(data: {}),
      targets: [],
      accessedAt: '', // Assign default or current date if needed
    );
  }

  User toEntity() {
    return User(
      id: userId,
      email: email,
      name: name,
      labels: labels.split(','),
      emailVerified: emailVerified,
    );
  }
}
