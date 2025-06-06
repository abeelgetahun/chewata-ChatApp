// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/models/user_model.dart';
import 'dart:async';

class AuthService extends GetxController {
  static AuthService get instance => Get.find();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Rx variables to track changes in user authentication
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  
  // Session timeout variables (30 minutes inactivity timeout)
  final int _sessionTimeoutMinutes = 30;
  Timer? _sessionTimer;
  final RxBool _isSessionActive = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Track user authentication state changes
    firebaseUser.bindStream(_auth.userChanges());
    // When firebaseUser changes, fetch user data from Firestore
    ever(firebaseUser, _setUserModel);
    
    // Start session management if user is logged in
    ever(firebaseUser, (user) {
      if (user != null) {
        _startSessionTimer();
      } else {
        _cancelSessionTimer();
      }
    });
  }
  
  // Fetch user data from Firestore when user logs in
  Future<void> _setUserModel(User? user) async {
    if (user != null) {
      userModel.value = await getUserDataFromFirestore(user.uid);
    } else {
      userModel.value = null;
    }
  }
  
  // Fetch user data from Firestore
  Future<UserModel?> getUserDataFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
  
  // Start session timer for inactivity logout
  void _startSessionTimer() {
    _cancelSessionTimer();
    _isSessionActive.value = true;
    
    _sessionTimer = Timer(Duration(minutes: _sessionTimeoutMinutes), () {
      // Session timeout - log the user out
      if (firebaseUser.value != null) {
        _isSessionActive.value = false;
        logout();
        Get.snackbar(
          'Session Expired', 
          'You have been logged out due to inactivity',
          duration: const Duration(seconds: 5),
        );
      }
    });
  }
  
  // Reset session timer on user activity
  void resetSessionTimer() {
    if (firebaseUser.value != null) {
      _startSessionTimer();
    }
  }
  
  // Cancel the session timer
  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
  
  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
  }) async {
    try {
      isLoading.value = true;
      
      // Validate password complexity
      if (!_isPasswordStrong(password)) {
        Get.snackbar(
          'Weak Password', 
          'Password must be at least 6 characters',
          duration: const Duration(seconds: 5),
        );
        return null;
      }
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          fullName: fullName,
          email: email,
          birthDate: birthDate,
          profilePicUrl: '',
          createdAt: DateTime.now(),
        );
        
        await _db.collection('users').doc(userCredential.user!.uid).set(user.toMap());
        
        // Start session timer
        _startSessionTimer();
        
        return userCredential;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong. Please try again.');
      print('SignUp Error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Email & Password Login
  Future<UserCredential?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      
      // Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Start session timer
      _startSessionTimer();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong. Please try again.');
      print('Login Error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Sign out
  Future<void> logout() async {
    try {
      _cancelSessionTimer();
      await _auth.signOut();
      Get.offAllNamed('/auth');
    } catch (e) {
      Get.snackbar('Error', 'Failed to log out. Please try again.');
      print('Logout Error: $e');
    }
  }
  
  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send password reset email.');
      print('Password Reset Error: $e');
    }
  }
  
  // Validate password strength
  bool _isPasswordStrong(String password) {
    // Minimum 6 characters
    return password.length >= 6;
  }
  
  // Handle Firebase Auth errors
  void handleFirebaseAuthError(FirebaseAuthException e) {
    String message = 'An error occurred. Please try again.';
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'The email address is already in use.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Check your connection.';
        break;
      default:
        message = 'An error occurred. Please try again.';
    }
    
    Get.snackbar('Authentication Error', message, duration: const Duration(seconds: 5));
  }
  
  @override
  void onClose() {
    _cancelSessionTimer();
    super.onClose();
  }
}