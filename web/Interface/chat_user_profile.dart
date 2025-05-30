class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;

  UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    required this.lastSeen,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }
}