// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/models/user_model.dart';

class AuthService extends GetxController {
  static AuthService get instance => Get.find();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Rx variables to track changes in user authentication
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Track user authentication state changes
    firebaseUser.bindStream(_auth.userChanges());
    // When firebaseUser changes, fetch user data from Firestore
    ever(firebaseUser, _setUserModel);
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
  
  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
  }) async {
    try {
      isLoading.value = true;
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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
      default:
        message = 'An error occurred. Please try again.';
    }
    
    Get.snackbar('Authentication Error', message);
  }
}