import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _userSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // প্রথমে Firebase থেকে লোড করার চেষ্টা করুন
      final loadedUser = await _firestoreService.getUser(uid);

      if (loadedUser != null) {
        _user = loadedUser;

        // Firebase থেকে ডেটা ক্যাশে সেভ করুন
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(loadedUser.toJson()));

        // Real-time updates এর জন্য স্ট্রিম সাবস্ক্রাইব করুন
        _userSubscription?.cancel(); // পুরানো সাবস্ক্রিপশন বন্ধ করুন
        _userSubscription = _firestoreService.getUserStream(uid).listen(
              (user) {
            if (user != null) {
              _user = user;
              // Real-time update ক্যাশে সেভ করুন
              _saveUserToCache(user);
              notifyListeners();
            }
          },
          onError: (error) {
            print('❌ User stream error: $error');
          },
        );
      } else {
        _error = 'User not found in Firebase';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('⚠️ Firebase user load failed, trying cache: $e');

      // Firebase ব্যর্থ হলে ক্যাশ থেকে লোড করুন
      await loadCachedUser();

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedUser() async {
    try {
      print('🔄 Loading user from cache...');
      final prefs = await SharedPreferences.getInstance();
      final cachedUserJson = prefs.getString('cached_user');

      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          final userMap = jsonDecode(cachedUserJson) as Map<String, dynamic>;
          _user = UserModel.fromJson(userMap);
          print('✅ Cached user loaded: ${_user?.name}');
          notifyListeners();
        } catch (parseError) {
          print('❌ Error parsing cached user JSON: $parseError');
          _error = 'Failed to parse cached user data';
          // Corrupted cache ডিলিট করুন
          await prefs.remove('cached_user');
        }
      } else {
        print('⚠️ No cached user data found');
        _error = 'No cached user data available';
      }
    } catch (e) {
      print('❌ Error loading cached user: $e');
      _error = 'Failed to load cached user';
    }
  }

  Future<void> _saveUserToCache(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(user.toJson()));
      print('💾 User saved to cache: ${user.name}');
    } catch (e) {
      print('❌ Error saving user to cache: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Firebase-এ আপডেট করুন
      await _firestoreService.updateUser(user);
      _user = user;

      // ক্যাশে সেভ করুন
      await _saveUserToCache(user);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update user: $e';
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(profileImageUrl: imageUrl);
      await updateUser(updatedUser);
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
      print('🗑️ User cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}