import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String hashedPassword;

  User({
    required this.username,
    required this.email,
    required this.hashedPassword,
  });
}