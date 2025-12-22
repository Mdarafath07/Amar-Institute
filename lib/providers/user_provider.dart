import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    _user = await _firestoreService.getUser(uid);
    _firestoreService.getUserStream(uid).listen((user) {
      _user = user;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    await _firestoreService.updateUser(user);
    _user = user;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(profileImageUrl: imageUrl);
      await updateUser(updatedUser);
    }
  }
}

