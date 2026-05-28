import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists user profile (name + avatar) to Firestore.
/// Uses the display name as the document ID so returning users
/// overwrite their previous entry (no auth required).
class UserProfileService {
  final FirebaseFirestore _db;

  UserProfileService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Saves/updates a user profile in Firestore.
  Future<void> saveProfile({
    required String displayName,
    required String avatar,
  }) async {
    if (displayName.isEmpty) return;
    await _db.collection('profiles').doc(displayName).set({
      'displayName': displayName,
      'avatar': avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates the user's high score if the new score is higher.
  Future<void> updateHighScore(String displayName, int newScore) async {
    if (displayName.isEmpty) return;
    
    final docRef = _db.collection('profiles').doc(displayName);
    final doc = await docRef.get();
    
    int currentHighScore = 0;
    if (doc.exists) {
      currentHighScore = (doc.data()?['highScore'] as num?)?.toInt() ?? 0;
    }
    
    if (newScore > currentHighScore) {
      await docRef.set({
        'highScore': newScore,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Fetches a profile by display name from Firestore.
  /// Returns null if the document doesn't exist.
  Future<Map<String, dynamic>?> fetchProfile(String displayName) async {
    final doc = await _db.collection('profiles').doc(displayName).get();
    return doc.exists ? doc.data() : null;
  }
}

/// Singleton provider for [UserProfileService].
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});
