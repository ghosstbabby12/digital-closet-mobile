import 'package:closet_ai/features/try_on/domain/look.dart';

extension LookJson on Look {
  static Look fromJson(Map<String, dynamic> json) => Look(
    id: json['id'] as int,
    imageUrl: json['image_url'] as String,
    garmentIds: (json['garment_ids'] as List).cast<int>(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
