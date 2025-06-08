# 🛂 AttendanceApp – Firestore Login System in Flutter

This is a Flutter-based login system for an attendance management app that uses **Cloud Firestore** instead of Firebase Authentication. The login flow supports two user roles: `admin` and `employee`.

---

## 🚀 Features

- Login using Firestore-stored email and password
- Role-based navigation:
  - Admin → `AdminDashboard()`
  - Employee → `EmployeeDashboard()`
- Validates email format and credential match
- Displays error messages for invalid email or incorrect password
- Firebase initialized with manual config via `FirebaseOptions`

---


