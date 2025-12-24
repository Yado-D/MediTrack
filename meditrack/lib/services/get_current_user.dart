import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/services/app_constants.dart';
import 'package:meditrack/services/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/domain/user_model.dart'; // Ensure this points to your Firebase UserM

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() => _instance;

  UserProvider._internal();

  UserM? _user;
  bool _isLoading = false;
  String _selectedAvatarPath = "assets/avatars/male_avatar2.png";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserM? get user => _user;

  bool get isLoading => _isLoading;

  String get avatarPath => _selectedAvatarPath;

  /// ----------------------------------------------------------------
  /// INITIALIZATION
  /// ----------------------------------------------------------------

  Future<bool> initUser() async {
    _setLoading(true);

    try {
      final prefs = await Global.storageServices;
      // 2. Get UUID from Local Storage
      final String? uuid = prefs.getUserId();

      print("......getting current user data user id is: $uuid....");
      if (uuid == null || uuid.isEmpty) {
        _setLoading(false);
        return false;
      }

      // 3. Fetch User Data from Firebase Firestore using UUID
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uuid).get();
      print("......getting current user data user data is: $doc....");

      if (doc.exists && doc.data() != null) {
        _user = UserM.fromMap(doc.data() as Map<String, dynamic>);
        print("......getting current user data  is: ${_user?.username}....");
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        // User document not found in Firestore
        await logout();
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint("UserProvider Error: $e");
      _setLoading(false);
      return false;
    }
  }

  /// ----------------------------------------------------------------
  /// STATE MODIFIERS
  /// ----------------------------------------------------------------

  Future<String?> getUuid() async {
    final prefs = await Global.storageServices.getUserId();
    return prefs;
  }

  Future<void> updateLocalAvatar(String assetPath) async {
    _selectedAvatarPath = assetPath;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_local_avatar_path', assetPath);
  }

  Future<void> refreshUser() async {
    await initUser();
  }

  Future<void> logout() async {
    _user = null;
    _selectedAvatarPath = "assets/avatars/male_avatar2.png";

    // 1. Clear Local Storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.UserId);

    // 2. Firebase Sign Out
    await _auth.signOut();

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
