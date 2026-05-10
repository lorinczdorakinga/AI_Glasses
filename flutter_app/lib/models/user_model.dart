class UserModel {
  final int id;
  final String name;
  final String email;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['id'],
        name:      json['name'],
        email:     json['email'],
        createdAt: json['created_at'] ?? '',
      );
}