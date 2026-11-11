import 'package:closet_ai/features/auth/domain/app_user.dart';

extension AppUserJson on AppUser {
  static AppUser fromJson(Map<String, dynamic> json) => AppUser(id: json['id'] as int, email: json['email'] as String);
}
