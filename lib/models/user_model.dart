// In user_model.dart, update the UserModel class

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final DateTime birthDate;
  final String profilePicUrl;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;
  
  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.birthDate,
    required this.profilePicUrl,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
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
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
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
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? 
          (map['lastSeen'] is DateTime ? 
              map['lastSeen'] : 
              map['lastSeen'] is Timestamp ? 
                  (map['lastSeen'] as Timestamp).toDate() : 
                  DateTime.parse(map['lastSeen'])) : 
          null,
    );
  }
}