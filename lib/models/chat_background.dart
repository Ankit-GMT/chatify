class ChatBackground {
  final int id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final String category;
  final String colorCode;

  ChatBackground({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.category,
    required this.colorCode,
  });

  factory ChatBackground.fromJson(Map<String, dynamic> json) {
    return ChatBackground(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      category: json['category'],
      colorCode: json['colorCode'],
    );
  }
}
