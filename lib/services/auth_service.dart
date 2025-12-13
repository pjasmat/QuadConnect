import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTER USER
  Future<String?> registerUser(String name, String email, String password) async {
    try {
      // Create user with Firebase Auth
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile in Firestore
      await _db.collection("users").doc(user.user!.uid).set({
        "uid": user.user!.uid,
        "name": name,
        "email": email,
        "bio": "",
        "profilePicUrl": "",
        "createdAt": Timestamp.now(),
      });

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN USER
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // CURRENT USER
  User? get currentUser => _auth.currentUser;
}
