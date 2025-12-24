import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/features/auth/domain/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper: Converts phone number to an internal email format
  // Example: +251911223344 -> 251911223344@meditrack.com
  String _formatPhoneToEmail(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return "$cleanPhone@meditrack.com";
  }

  // SIGN UP
  Future<User?> signUp({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: _formatPhoneToEmail(phone),
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Save Additional Info to Firestore
        UserM newUser = UserM(
          uid: user.uid,
          username: name,
          phone: phone,
          createdAt: DateTime.now(),
          password: password,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  // SIGN IN
  Future<User?> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: _formatPhoneToEmail(phone),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // GET CURRENT USER DATA
  Future<UserM?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserM.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Error Handling Wrapper
  String _handleAuthException(FirebaseAuthException e) {
    print(e.toString());
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this phone number.';
      case 'user-not-found':
        return 'No user found for this phone number.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}
