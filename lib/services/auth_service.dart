import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';
  static const String _keyUsers = 'users';

  static FirebaseAuth? _auth;

  static FirebaseAuth? get _firebaseAuth {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth;
    } catch (e) {
      print('Firebase Auth not available: $e');
      return null;
    }
  }

  // Check if Firebase is available
  static bool get isFirebaseAvailable => _firebaseAuth != null;

  // Get current user
  static User? get currentUser => _firebaseAuth?.currentUser;

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    if (isFirebaseAvailable && currentUser != null) {
      return true;
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current username
  static Future<String?> getCurrentUsername() async {
    if (isFirebaseAvailable && currentUser != null) {
      return currentUser!.email?.split('@')[0] ?? currentUser!.email;
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    if (isFirebaseAvailable && currentUser != null) {
      return currentUser!.uid;
    }

    // Fallback to local username
    return await getCurrentUsername();
  }

  // Firebase Authentication - Sign in
  static Future<bool> loginWithFirebase(String email, String password) async {
    if (!isFirebaseAvailable) return false;

    try {
      print('Attempting Firebase login for: $email');
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase login successful for: $email');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      print('Firebase login error code: ${e.code}');
      print('Firebase login error message: ${e.message}');

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email. Please sign up first.';
        case 'wrong-password':
          throw 'Incorrect password. Please try again.';
        case 'user-disabled':
          throw 'This account has been disabled.';
        case 'too-many-requests':
          throw 'Too many failed attempts. Please try again later.';
        case 'invalid-email':
          throw 'Invalid email format.';
        case 'network-request-failed':
          throw 'Network error. Please check your connection.';
        case 'invalid-credential':
          throw 'Invalid email or password.';
        default:
          throw e.message ?? 'Firebase login failed';
      }
    } catch (e) {
      print('Firebase login unexpected error: $e');
      throw 'Login failed: $e';
    }
  }

  // Firebase Authentication - Sign up
  static Future<bool> registerWithFirebase(
      String email, String password) async {
    if (!isFirebaseAvailable) return false;

    try {
      print('Attempting Firebase registration for: $email');
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase registration successful for: $email');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      print('Firebase register error code: ${e.code}');
      print('Firebase register error message: ${e.message}');

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'weak-password':
          throw 'Password is too weak. Please use at least 6 characters.';
        case 'email-already-in-use':
          throw 'An account with this email already exists. Please sign in instead.';
        case 'invalid-email':
          throw 'Invalid email format.';
        case 'network-request-failed':
          throw 'Network error. Please check your connection.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled. Please contact support.';
        default:
          throw e.message ?? 'Firebase registration failed';
      }
    } catch (e) {
      print('Firebase register unexpected error: $e');
      throw 'Registration failed: $e';
    }
  }

  // Unified login (tries Firebase first, falls back to local)
  static Future<bool> login(String username, String password) async {
    // Try Firebase first if available and input looks like email
    if (isFirebaseAvailable && username.contains('@')) {
      try {
        return await loginWithFirebase(username, password);
      } catch (e) {
        print('Firebase login failed, trying local: $e');
        // Fall through to local auth
      }
    }

    // Local authentication fallback
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList(_keyUsers) ?? [];

    // Check for default admin user
    if (username == 'admin' && password == 'admin') {
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUsername, username);
      return true;
    }

    // Check for registered users
    for (String user in users) {
      final parts = user.split(':');
      if (parts.length == 2 && parts[0] == username && parts[1] == password) {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUsername, username);
        return true;
      }
    }

    return false;
  }

  // Unified register (tries Firebase first, falls back to local)
  static Future<bool> register(String username, String password) async {
    // Try Firebase first if available and input looks like email
    if (isFirebaseAvailable && username.contains('@')) {
      try {
        return await registerWithFirebase(username, password);
      } catch (e) {
        print('Firebase register failed, trying local: $e');
        // Fall through to local auth
      }
    }

    // Local registration fallback
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList(_keyUsers) ?? [];

    // Check if username already exists
    for (String user in users) {
      final parts = user.split(':');
      if (parts.length == 2 && parts[0] == username) {
        return false; // Username already exists
      }
    }

    // Add new user
    users.add('$username:$password');
    await prefs.setStringList(_keyUsers, users);
    return true;
  }

  // Logout user
  static Future<void> logout() async {
    if (isFirebaseAvailable && currentUser != null) {
      await _firebaseAuth!.signOut();
    }

    // Also clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUsername);
  }

  // Listen to auth state changes
  static Stream<User?> get authStateChanges {
    if (isFirebaseAvailable) {
      return _firebaseAuth!.authStateChanges();
    } else {
      // Return empty stream for local auth
      return Stream.empty();
    }
  }
}