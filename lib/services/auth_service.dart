import 'package:attendanceapp/screens/admin_with_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/employee_dashboard.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loginUsingFirestore(
      String email, String password, BuildContext context) async {
    // Validate email format
    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$").hasMatch(email)) {
      showError(context, "Please enter a valid email address");
      return;
    }

    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('user').doc(email).get();

      if (!userDoc.exists) {
        showError(context, "Invalid email. User not found");
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      if (data['password'] != password) {
        showError(context, "Incorrect password. Please try again");
        return;
      }

      final role = data['role'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
      await _firestore.collection('user').doc(email).update({'isLoggedIn': true});
      await prefs.setString('loggedInUserId', data['userId'].toString());
      await prefs.setString('userId', data['userId'].toString());
      await prefs.setString('userName', data['name'] ?? 'Unknown');
      await prefs.setString('userRole', role);


      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminHomeWithCalendar()),
        );
      } else if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeDashboard(email: email),
          ),
        );

      } else {
        showError(context, "Unknown role: $role");
      }
    } catch (e) {
      showError(context, "Login failed: $e");
    }
  }

  void showError(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
