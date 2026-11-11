/// An AI-generated photo of the user wearing garments from their closet.
class Look {
  final int id;
  final String imageUrl;
  final List<int> garmentIds;
  final DateTime createdAt;

  Look({required this.id, required this.imageUrl, required this.garmentIds, required this.createdAt});
}
