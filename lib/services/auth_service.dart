import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Example placeholders
import '../screens/admin_dashboard.dart';
import '../screens/employee_dashboard.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
      print("🔥 Firebase Auth instance: ${FirebaseAuth.instance.app.name}");
      print("🔥 Firestore instance: ${FirebaseFirestore.instance.app.name}");

    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // 2. Fetch user document from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('user').doc(email).get();

      if (!userDoc.exists) {
        // User document doesn't exist
        showError(context, "User not found in database");
        return;
      }

      // 3. Check role field
      String role = userDoc.get('role'); // should be 'admin' or 'employee'

      // 4. Navigate based on role
      if (role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminDashboard()));
      } else if (role == 'employee') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => EmployeeDashboard()));
      } else {
        showError(context, "Unknown role found in database");
      }
    } on FirebaseAuthException catch (e) {
      showError(context, e.message ?? "Authentication failed");
    } catch (e) {
      showError(context, "Unexpected error: $e");
    }
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}
