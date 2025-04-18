// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthService extends GetxController {
  static AuthService get instance => Get.find();
  
  // Variables
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  // Initialize firebaseUser in the constructor
  late final Rx<User?> firebaseUser = Rx<User?>(_auth.currentUser);
  var verificationId = ''.obs;
  
  // Will be loaded when app launches
  @override
  void onReady() {
    // Just set up the stream binding, the variable is already initialized
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
    super.onReady();
  }
  
  // Setting initial screen
  _setInitialScreen(User? user) {
    if (user == null) {
      // User is not logged in
      // You can handle navigation here if needed
    } else {
      // User is logged in
      // You can handle navigation here if needed
    }
  }

  // LOGIN
  Future<bool> loginWithEmailAndPassword(String emailOrPhone, String password) async {
    try {
      // Try login with email
      if (emailOrPhone.contains('@')) {
        await _auth.signInWithEmailAndPassword(email: emailOrPhone, password: password);
      } else {
        // Login with phone number (username)
        // First query Firestore to find the user with this username
        final userDocs = await _firestore.collection('users')
            .where('username', isEqualTo: emailOrPhone)
            .limit(1)
            .get();
        
        if (userDocs.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this username',
          );
        }
        
        // Get the email associated with this username
        final userEmail = userDocs.docs.first.data()['email'];
        
        // Now sign in with email and password
        await _auth.signInWithEmailAndPassword(
          email: userEmail, 
          password: password
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Authentication Error',
        e.message ?? 'Failed to login. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }
  }

  // REGISTER
  Future<bool> registerWithEmailAndPassword(String email, String password, String fullName, String username, int age, String phone) async {
    try {
      // First check if username already exists
      final usernameCheck = await _firestore.collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (usernameCheck.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-exists',
          message: 'Username already exists',
        );
      }
      
      // Create the user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'username': username,
        'age': age,
        'phone': phone,
        'email': email,
        'createdAt': Timestamp.now(),
      });
      
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Registration Error',
        e.message ?? 'Failed to register. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async => await _auth.signOut();
}