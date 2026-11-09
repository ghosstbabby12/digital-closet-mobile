/// Foto generada con IA del usuario vistiendo prendas de su clóset.
class Look {
  final int id;
  final String imageUrl;
  final List<int> garmentIds;
  final DateTime createdAt;

  Look({required this.id, required this.imageUrl, required this.garmentIds, required this.createdAt});

  factory Look.fromJson(Map<String, dynamic> json) {
    return Look(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      garmentIds: (json['garment_ids'] as List).cast<int>(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
