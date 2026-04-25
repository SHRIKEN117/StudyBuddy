class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? json['_id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        profileImage: json['profileImage'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
