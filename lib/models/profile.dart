/// Datos del perfil del usuario con los totales de su actividad.
class Profile {
  final int id;
  final String email;
  final DateTime createdAt;
  final int garmentCount;
  final int outfitCount;
  final int lookCount;
  final bool hasBodyPhoto;

  Profile({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.garmentCount,
    required this.outfitCount,
    required this.lookCount,
    required this.hasBodyPhoto,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      garmentCount: json['garment_count'] as int,
      outfitCount: json['outfit_count'] as int,
      lookCount: json['look_count'] as int,
      hasBodyPhoto: json['has_body_photo'] as bool,
    );
  }
}
