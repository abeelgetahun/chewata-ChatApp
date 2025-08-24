import 'package:chewata/controller/account_controller.dart';
import 'package:chewata/utils/link.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  // Add presence variables
  StreamSubscription? _presenceSubscription;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Initialize Firebase Realtime Database with the correct URL
  AuthService() {
    // Set the database URL
    _database.databaseURL = TLink.realtimeDatabase;

    // Configure the connection state persistence
    try {
      _database.setPersistenceEnabled(true);
      print('Firebase Realtime Database persistence enabled');
    } catch (e) {
      print('Error setting persistence: $e');
    }
  }

  // Session timeout variables (7 days inactivity timeout)
  // If the user doesn't interact with the app for this duration, they will be logged out.
  final Duration _sessionTimeout = const Duration(days: 7);
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
        // Set user as online when they log in or app starts with logged in user
        updatePresence(true);
      } else {
        _cancelSessionTimer();
        // Cancel presence subscription when user logs out
        _presenceSubscription?.cancel();
        _presenceSubscription = null;
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

    _sessionTimer = Timer(_sessionTimeout, () {
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

        await _db
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());

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
      // Update online status after successful login
      await updatePresence(true);

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

  // Sign out - fixed version
  Future<void> logout() async {
    try {
      _cancelSessionTimer();

      if (firebaseUser.value != null) {
        // Wait for presence update to complete before signing out
        await updatePresence(false);

        // Clear the user model before signing out
        userModel.value = null;

        // Add a small delay to ensure database operations complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Now sign out
        await _auth.signOut();
      } else {
        await _auth.signOut();
      }

      // Notify any controllers that might need to clear their data
      Get.find<AccountController>().clearUserData();

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
      Get.snackbar(
        'Success',
        'Password reset email sent. Please check your inbox.',
      );
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

    Get.snackbar(
      'Authentication Error',
      message,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    // Make sure to set user as offline when service is closed
    if (firebaseUser.value != null) {
      updatePresence(false);
    }
    _cancelSessionTimer();
    _presenceSubscription?.cancel();
    super.onClose();
  }

  // Add this method to auth_service.dart (just before the updatePresence method)

  // This method returns a Future that completes when initial data is loaded
  Future<bool> waitForInitialDataLoad() async {
    try {
      if (firebaseUser.value == null) {
        return false;
      }

      // Wait for user model to be loaded
      if (userModel.value == null) {
        // Wait for user data to be fetched
        await Future.delayed(Duration(milliseconds: 500));
        if (userModel.value == null) {
          return false;
        }
      }

      // Signal that initial data is loaded
      return true;
    } catch (e) {
      print('Error waiting for initial data: $e');
      return false;
    }
  }

  Future<void> updatePresence(bool isOnline) async {
    try {
      final user = firebaseUser.value;
      if (user == null) {
        print('Cannot update presence: No user logged in');
        return;
      }

      print('Updating presence for user ${user.uid}: isOnline=$isOnline');

      // First (optimistic) update Firestore for UI immediacy
      await _db.collection('users').doc(user.uid).set({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update user model if needed
      if (userModel.value != null) {
        userModel.value = UserModel(
          id: userModel.value!.id,
          fullName: userModel.value!.fullName,
          email: userModel.value!.email,
          birthDate: userModel.value!.birthDate,
          profilePicUrl: userModel.value!.profilePicUrl,
          createdAt: userModel.value!.createdAt,
          isOnline: isOnline,
          lastSeen: isOnline ? null : DateTime.now(),
        );
      }

      // Make sure user is still authenticated before updating Realtime Database
      if (_auth.currentUser != null) {
        // Also update Realtime Database, ensuring onDisconnect is set before online
        final userStatusRef = _database.ref('status/${user.uid}');
        if (isOnline) {
          // Setup onDisconnect first, then set online
          await userStatusRef.onDisconnect().set({
            'online': false,
            'lastChanged': ServerValue.timestamp,
          });
          await userStatusRef.set({
            'online': true,
            'lastChanged': ServerValue.timestamp,
          });
          _setupPresenceDisconnectHook(user.uid);
        } else {
          // Explicit offline: set offline and clear listeners
          await userStatusRef.set({
            'online': false,
            'lastChanged': ServerValue.timestamp,
          });
          _presenceSubscription?.cancel();
          _presenceSubscription = null;
        }
      } else {
        print('Cannot update Realtime Database: User not authenticated');
      }
    } catch (e) {
      print('Error updating presence: $e');
    }
  }

  // Add this method to handle unexpected disconnects
  void _setupPresenceDisconnectHook(String userId) {
    try {
      // Cancel any existing subscription first
      _presenceSubscription?.cancel();

      // Make sure user is still authenticated
      if (_auth.currentUser == null) {
        print('Cannot set up disconnect hook: User not authenticated');
        return;
      }

      print('Setting up presence disconnect hook for user: $userId');

      // Create a reference to this user's presence in Realtime Database
      final userStatusRef = _database.ref('status/$userId');

      // Create a reference to the special '.info/connected' path
      final connectedRef = _database.ref('.info/connected');

      // Listen for connection state changes
      _presenceSubscription = connectedRef.onValue.listen((event) {
        // Make sure user is still authenticated
        if (_auth.currentUser == null) {
          print('User no longer authenticated, cancelling presence updates');
          _presenceSubscription?.cancel();
          return;
        }

        print('Connection state changed: ${event.snapshot.value}');
        final connected = event.snapshot.value as bool? ?? false;
        if (!connected) {
          print('Device disconnected');
          return;
        }

        print('Device connected, setting up onDisconnect');

        // When we disconnect, update the database
        userStatusRef
            .onDisconnect()
            .set({'online': false, 'lastChanged': ServerValue.timestamp})
            .then((_) {
              print('onDisconnect handler set up successfully');

              // Set the user as online in the Realtime Database
              userStatusRef
                  .set({'online': true, 'lastChanged': ServerValue.timestamp})
                  .then((_) {
                    print('User set as online in Realtime Database');
                  })
                  .catchError((error) {
                    print('Error setting online status: $error');
                  });

              // Also set up a listener to sync Realtime DB status to Firestore
              _setupFirestoreSyncFromRealtimeDB(userId);
            })
            .catchError((error) {
              print('Error setting up onDisconnect handler: $error');
            });
      });
    } catch (e) {
      print('Error setting up presence disconnect hook: $e');
    }
  }

  // Add this method to sync Realtime Database status to Firestore
  void _setupFirestoreSyncFromRealtimeDB(String userId) {
    try {
      final userStatusRef = _database.ref('status/$userId');

      // Listen for changes to the user's status in Realtime Database
      userStatusRef.onValue.listen((event) {
        if (event.snapshot.value == null) return;

        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final isOnline = data['online'] as bool? ?? false;

        // Mirror RTDB presence to Firestore for both transitions
        if (!isOnline) {
          _db.collection('users').doc(userId).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } else {
          _db.collection('users').doc(userId).update({
            'isOnline': true,
            'lastSeen': null,
          });
        }
      });
    } catch (e) {
      print('Error setting up Firestore sync: $e');
    }
  }
}
