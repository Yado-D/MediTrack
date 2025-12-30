import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/features/home/domain/med_user_data.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- IMPROVED ERROR HANDLER ---
  String _handleError(String action, dynamic e) {
    // 1. Log the RAW error to console so you can see the technical details
    dev.log("FAILURE: [$action] - $e", name: "MedicationService", error: e);

    // 2. Handle Firebase Specific Errors
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return "Access denied. Please ensure you are logged in.";
        case 'unavailable':
          return "Network error. Please check your internet connection.";
        case 'not-found':
          return "The requested medication data was not found.";
        case 'deadline-exceeded':
          return "The connection timed out. Please try again.";
        case 'already-exists':
          return "This record already exists.";
        default:
          return "Database error: [${e.code}] ${e.message}";
      }
    }

    // 3. Handle Manual Logic Errors (Like your "Limit of 2" check)
    // When you throw Exception("Message"), Dart adds "Exception: " to the string.
    // We clean it up here.
    if (e is Exception) {
      return e.toString().replaceAll("Exception: ", "");
    }

    // 4. Handle generic errors
    return "An unexpected error occurred: $e";
  }

  // 1. ADD OR UPDATE MEDICATION
  Future<void> addUserSchedule(String userId, MedicationModel med) async {
    dev.log("Action: Adding schedule '${med.name}' for user: $userId",
        name: "MedicationService");

    try {
      // Step A: Check existing count
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          .get();

      // Step B: Check for duplicates or limits
      // (Optional: Check if this specific pill ID already exists to allow updating it)
      final bool isExistingUpdate =
          snapshot.docs.any((doc) => doc.id == med.id.toString());

      if (!isExistingUpdate && snapshot.docs.length >= 2) {
        // This validates the Limit.
        // We throw a standard Exception, which our new _handleError will now recognize.
        throw Exception("Sorry, you can only add two medications.");
      }

      // Step C: Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          .doc(med.id.toString())
          .set(med.toMap());

      dev.log("Success: Added/Updated ${med.name}", name: "MedicationService");
    } catch (e) {
      // This sends the error to your UI
      throw _handleError("addUserSchedule", e);
    }
  }

  // 2. FETCH ALL MEDICATIONS FOR A USER
  Future<List<MedicationModel>> fetchUserSchedules(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          // It's good practice to try-catch the parsing too,
          // in case data in DB doesn't match the Model
          .orderBy('created_at', descending: true)
          .get();

      final meds = snapshot.docs.map((doc) {
        try {
          return MedicationModel.fromMap(doc.data() as Map<String, dynamic>);
        } catch (e) {
          dev.log("Error parsing doc ${doc.id}: $e", name: "MedicationService");
          // Return null or handle corrupted data safely if needed
          rethrow;
        }
      }).toList();

      return meds;
    } catch (e) {
      throw _handleError("fetchUserSchedules", e);
    }
  }

  // 3. UPDATE PILL COUNT
  Future<void> updatePillCount(String userId, int medId, int newCount) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          .doc(medId.toString())
          .update({'total_pills_count': newCount});

      dev.log("Success: Updated pill count to $newCount",
          name: "MedicationService");
    } catch (e) {
      throw _handleError("updatePillCount", e);
    }
  }

  // 4. DELETE MEDICATION
  Future<void> deleteMedication(String userId, int medId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medSchedules')
          .doc(medId.toString())
          .delete();

      dev.log("Success: Deleted medication $medId", name: "MedicationService");
    } catch (e) {
      throw _handleError("deleteMedication", e);
    }
  }
}
