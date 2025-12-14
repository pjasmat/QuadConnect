import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // REGISTER USER
  // ------------------------------------------------------------
  Future<String?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Create user
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile document
      await _db.collection("users").doc(user.user!.uid).set({
        "uid": user.user!.uid,
        "username":
            name, // Changed from "name" to "username" to match AppUser model
        "name": name, // Keep "name" for backward compatibility
        "email": email,
        "bio": "",
        "profilePicUrl": "",
        "photoUrl": "", // Add photoUrl field for consistency
        "followers": [],
        "following": [],
        "createdAt": Timestamp.now(),
      });

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ------------------------------------------------------------
  // LOGIN USER
  // ------------------------------------------------------------
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Ensure user document exists in Firestore (in case user signed up before Firestore was enabled)
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection("users").doc(user.uid).get();
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          final defaultName =
              user.displayName ?? user.email?.split('@')[0] ?? "User";
          await _db.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "username":
                defaultName, // Changed from "name" to "username" to match AppUser model
            "name": defaultName, // Keep "name" for backward compatibility
            "email": user.email ?? "",
            "bio": "",
            "profilePicUrl": "",
            "photoUrl": "", // Add photoUrl field for consistency
            "followers": [],
            "following": [],
            "createdAt": Timestamp.now(),
          });
        }
      }

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ------------------------------------------------------------
  // PASSWORD RESET
  // ------------------------------------------------------------
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ------------------------------------------------------------
  // CURRENT USER (Firebase Auth)
  // ------------------------------------------------------------
  User? get currentUser => _auth.currentUser;
}
