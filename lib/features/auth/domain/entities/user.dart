import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final List<String> labels;
  final bool emailVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.labels,
    this.emailVerified = false,
  });

  @override
  List<Object> get props => [id, email, name, labels, emailVerified];

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, labels: $labels, emailVerified: $emailVerified)';
}
