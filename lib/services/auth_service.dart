import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // REGISTER USER
  // ------------------------------------------------------------
  Future<String?> registerUser(String name, String email, String password) async {
    try {
      // Create user
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile document
      await _db.collection("users").doc(user.user!.uid).set({
        "uid": user.user!.uid,
        "name": name,
        "email": email,
        "bio": "",
        "profilePicUrl": "",
        "followers": [],   // <-- ADDED
        "following": [],   // <-- ADDED
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
          await _db.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "name": user.displayName ?? user.email?.split('@')[0] ?? "User",
            "email": user.email ?? "",
            "bio": "",
            "profilePicUrl": "",
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
  // CURRENT USER (Firebase Auth)
  // ------------------------------------------------------------
  User? get currentUser => _auth.currentUser;
}
