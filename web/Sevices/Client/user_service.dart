import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final usersById = await _firestore
        .collection('users')
        .where('id', isEqualTo: query)
        .get();

    final usersByEmail = await _firestore
        .collection('users')
        .where('email', isEqualTo: query)
        .get();

    return [...usersById.docs, ...usersByEmail.docs]
        .map((doc) => doc.data())
        .toList();
  }
}