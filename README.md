# 📲 AttendEase

**AttendEase** is a cross-platform Attendance Management System built using **Flutter** and **Firebase**, designed to simplify, digitize, and automate attendance tracking, leave management, and HR operations in organizations.

---

## 🚀 Features

### 🔐 Authentication
- Email-based secure login system for Admins and Employees.
- Forgot Password and Reset flow using Firebase Authentication.

### 🧑‍💼 Role-Based Dashboards
- **Admin Dashboard:**
  - Manage Employees (CRUD)
  - View & Edit Attendance Records
  - Handle Leave Requests and Comp Offs
  - Maintain Leave Calendar and Holidays
  - QR Code Verification for attendance
  - Manage Codes and Policies

- **Employee Dashboard:**
  - View personal Attendance Summary
  - Apply for Leave / Comp Off
  - Check Leave Status
  - View Organizational Codes and Policies
  - Mark Attendance by Scanning QR Code

### 📆 Attendance Management
- QR Code-based Check-In and Check-Out system.
- Real-time attendance recording with validations.
- Admin override for editing check-in/out or status.
- PDF generation for date-wise attendance reports.

### 📌 Leave Management
- Apply for various leave types (fetched from `codes_master`).
- Admin can approve/reject with comments.
- Real-time leave status with color indicators and remarks.

### 📋 Policy & Code Management
- Admins can create, update, or deactivate company policies and code values.
- Employees can view latest updates in a clean UI.

### 🌐 Cloud Backend
- Firebase Firestore for storing and syncing all data in real time.
- Firebase Authentication for login and session control.
- QR code generation and validation using `qr_flutter`.

## 🔧 Tech Stack

| Technology     | Purpose                             |
|----------------|-------------------------------------|
| Flutter        | Frontend UI                         |
| Firebase Auth  | Authentication                     |
| Cloud Firestore| Realtime Database                   |
| Provider       | State Management                    |
| qr_flutter     | QR Code generation and display      |
| intl           | Date formatting and manipulation    |

---
## Documentation
📄 [Download Full Project Documentation](lib/documentation_materials/Documentation.pdf)


---

## 📄 Conclusion

**AttendEase** offers a modern, digital-first approach to handling attendance, combining secure authentication, QR-based validation, and real-time reporting. With its modular design, clean UI, and scalable backend, it’s a reliable solution for organizations aiming to automate and optimize their HR operations.

> ⚡ *Smart Attendance. Easy Management. That’s AttendEase.*

---

## 👨‍💻 Developed By
**Sanjana V**  
_Ainsurtech Internship Final Project_

---
