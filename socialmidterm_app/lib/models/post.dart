class Post {
  final String id;
  final String imageUrl; // Maps to 'ImageUrl' in DB
  final String caption;
  final String username;
  final String profileImage;
  final String uid;
  final String likes; // Stored as String per screenshot
  final DateTime timestamp;

  Post({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.username,
    required this.profileImage,
    required this.uid,
    required this.likes,
    required this.timestamp,
  });
}