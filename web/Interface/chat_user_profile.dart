class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;
  String? email;
  String? phoneNumber;
  String? bio;
  List<String> friends;

  UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    required this.lastSeen,
    this.email,
    this.phoneNumber,
    this.bio,
    this.friends = const [],
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'email': email,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'friends': friends,
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
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      bio: json['bio'],
      friends: List<String>.from(json['friends'] ?? []),
    );
  }

  // Update profile details
  UserProfile updateProfile({
    String? name,
    String? avatarUrl,
    String? email,
    String? phoneNumber,
    String? bio,
    List<String>? friends,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline,
      lastSeen: lastSeen,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      friends: friends ?? this.friends,
    );
  }

  // Check how long ago user was last seen
  String getLastSeenDuration() {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    if (difference.inMinutes < 1) return "Just now";
    if (difference.inHours < 1) return "${difference.inMinutes} minutes ago";
    if (difference.inDays < 1) return "${difference.inHours} hours ago";
    return "${difference.inDays} days ago";
  }

  // Add a friend
  void addFriend(String friendId) {
    if (!friends.contains(friendId)) {
      friends.add(friendId);
    }
  }

  // Remove a friend
  void removeFriend(String friendId) {
    friends.remove(friendId);
  }
}