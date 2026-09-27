class AppUser {
  final int id;
  final String email;

  AppUser({required this.id, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(id: json['id'] as int, email: json['email'] as String);
  }
}
