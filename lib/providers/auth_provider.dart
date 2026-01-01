import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineMode = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isOfflineMode => _isOfflineMode;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (!_isOfflineMode) {
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser != null) {
          await loadUser();
        } else {
          _user = null;
          notifyListeners();
        }
      });
    }
  }

  Future<void> loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      _isOfflineMode = prefs.getBool('is_online') == false;

      final cachedUserJson = prefs.getString('cached_user');
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
          _user = UserModel.fromJson(userMap);
          _isLoading = false;
          notifyListeners();
        } catch (e) {
          print(' Error parsing cached user JSON: $e');
          await prefs.remove('cached_user');
        }
      }

      if (!_isOfflineMode) {
        try {
          final firebaseUser = _authService.currentUser;
          if (firebaseUser != null) {
            final firestoreService = FirestoreService();
            final freshUser = await firestoreService.getUser(firebaseUser.uid);
            if (freshUser != null) {
              _user = freshUser;
              await prefs.setString('cached_user', jsonEncode(freshUser.toJson()));
              await prefs.setBool('is_online', true);
            }
          }
        } catch (e) {
          print('Firebase user load failed (offline mode active): $e');
          _isOfflineMode = true;
          await prefs.setBool('is_online', false);

          if (_user == null && cachedUserJson != null && cachedUserJson.isNotEmpty) {
            try {
              final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
              _user = UserModel.fromJson(userMap);
            } catch (e) {
              print('Error loading from cache after Firebase failure: $e');
            }
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in loadUser(): $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserJson = prefs.getString('cached_user');
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
        _user = UserModel.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      print(' Error loading cached user: $e');
    }
  }



  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String department,
    required String semester,
    String? rollNo,
    String? regNo,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        department: department,
        semester: semester,
        rollNo: rollNo,
        regNo: regNo,
        phoneNumber: phoneNumber,
      );

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_user!.toJson()));
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'This email is already registered. Please sign in.';
          break;
        case 'weak-password':
          _errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          _errorMessage = e.message ?? 'Sign up failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_user!.toJson()));
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many attempts. Try again later.';
          break;
        default:
          _errorMessage = e.message ?? 'Sign in failed. Please check your credentials.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many attempts. Try again later.';
          break;
        default:
          _errorMessage = e.message ?? 'Failed to send reset email. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (!_isOfflineMode) {
      await _authService.signOut();
    }
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }
}