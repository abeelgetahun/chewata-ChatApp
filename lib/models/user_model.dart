// lib/models/user_model.dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final DateTime birthDate;
  final String profilePicUrl;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.birthDate,
    required this.profilePicUrl,
    required this.createdAt,
  });
  
  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'birthDate': birthDate.toIso8601String(),
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      birthDate: DateTime.parse(map['birthDate']),
      profilePicUrl: map['profilePicUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}