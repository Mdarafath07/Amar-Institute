import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp({
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          department: department,
          semester: semester,
          rollNo: rollNo,
          regNo: regNo,
          phoneNumber: phoneNumber,
        );

        await _firestoreService.createUser(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {

      rethrow;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await _firestoreService.getUser(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {

      rethrow;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
// Firebase specific errors rethrow with original exception
      rethrow;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}
