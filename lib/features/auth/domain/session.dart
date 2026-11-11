import 'package:closet_ai/features/auth/domain/app_user.dart';

/// A signed-in user and the token that proves it to the API.
class Session {
  final String token;
  final AppUser user;

  const Session({required this.token, required this.user});
}
