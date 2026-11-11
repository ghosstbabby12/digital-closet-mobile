/// The user's account details plus totals of their activity.
class Profile {
  final int id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final int garmentCount;
  final int outfitCount;
  final int lookCount;
  final bool hasBodyPhoto;

  Profile({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    required this.garmentCount,
    required this.outfitCount,
    required this.lookCount,
    required this.hasBodyPhoto,
  });

  /// The name when there is one, otherwise the email.
  String get displayName => (name?.isNotEmpty ?? false) ? name! : email;
}
