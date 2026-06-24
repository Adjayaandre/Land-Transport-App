class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // driver | admin | supervisor
  final String? avatarUrl;

  const UserModel({required this.id, required this.name, required this.email, required this.role, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'], name: json['name'], email: json['email'], role: json['role'], avatarUrl: json['avatar_url'],
  );
}
