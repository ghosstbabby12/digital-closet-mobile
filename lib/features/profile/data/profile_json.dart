import 'package:closet_ai/features/profile/domain/profile.dart';

extension ProfileJson on Profile {
  static Profile fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    garmentCount: json['garment_count'] as int,
    outfitCount: json['outfit_count'] as int,
    lookCount: json['look_count'] as int,
    hasBodyPhoto: json['has_body_photo'] as bool,
  );
}
