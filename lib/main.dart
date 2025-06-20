import 'package:attendanceapp/screens/admin_with_calendar.dart';
import 'package:attendanceapp/screens/employee_dashboard.dart';
import 'package:attendanceapp/screens/login_screen.dart';
import 'package:attendanceapp/themes/app_theme.dart';
import 'package:attendanceapp/themes/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDPJk7IKBjyILFlmCGA9IoWRG47vGRmddM",
      appId: "1:730550453202:android:a45f5f971fd47185c17e0b",
      messagingSenderId: "730550453202",
      projectId: "attendance-app-71bf4",
      storageBucket: "attendance-app-71bf4.appspot.com",
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('userEmail');
  Widget home = const LoginScreen();

  if (email != null && email.isNotEmpty) {
    final userDoc = await FirebaseFirestore.instance.collection('user').doc(email).get();
    if (userDoc.exists && userDoc['isLoggedIn'] == true) {
      final role = userDoc['role'];
      if (role == 'admin') {
        home = const AdminHomeWithCalendar();
      } else {
        home = EmployeeDashboard(email: email);
      }
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(home: home),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Attendance App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:themeProvider.themeMode,
          home: home,
        );
      },
    );
  }
}

