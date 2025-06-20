import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final String userId;
  final String name;

  const EmployeeAttendanceScreen({super.key, required this.userId, required this.name});

  @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  final attendanceRef = FirebaseFirestore.instance.collection('attendance');
  late String docId;
  Map<String, dynamic>? attendanceData;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    docId = "${widget.userId}_${DateFormat('ddMMyyyy').format(today)}";
    _fetchTodayAttendance();
  }

  Future<void> _fetchTodayAttendance() async {
    final snapshot = await attendanceRef.doc(docId).get();
    if (snapshot.exists) {
      setState(() => attendanceData = snapshot.data());
    }
  }

  Future<void> _checkIn() async {
    final now = DateTime.now();
    final data = {
      'userId': widget.userId,
      'name': widget.name,
      'date': Timestamp.fromDate(now),
      'checkInTime': Timestamp.fromDate(now),
      'status': 'Present',
      'markedby': 'self',
      'createdBy': 'self',
      'updatedOn': Timestamp.now(),
      'updatedBy': 'self'
    };
    await attendanceRef.doc(docId).set(data);
    _fetchTodayAttendance();
  }

  Future<void> _checkOut() async {
    final now = DateTime.now();
    await attendanceRef.doc(docId).update({
      'checkOutTime': Timestamp.fromDate(now),
      'updatedOn': Timestamp.now(),
      'updatedBy': 'admin'
    });
    _fetchTodayAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = attendanceData?['checkInTime'] as Timestamp?;
    final checkOut = attendanceData?['checkOutTime'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance"),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            if (checkIn == null)
              ElevatedButton(
                onPressed: _checkIn,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Check In"),
              )
            else
              Text("Checked in at: ${DateFormat.Hm().format(checkIn.toDate())}"),

            const SizedBox(height: 16),

            if (checkIn != null && checkOut == null)
              ElevatedButton(
                onPressed: _checkOut,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Check Out"),
              )
            else if (checkOut != null)
              Text("Checked out at: ${DateFormat.Hm().format(checkOut.toDate())}"),

            const SizedBox(height: 16),
            if (checkIn != null && checkOut != null)
              Text("Worked: ${_calculateHoursWorked(checkIn, checkOut)}")
          ],
        ),
      ),
    );
  }

  String _calculateHoursWorked(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return "-";
    final duration = checkOut.toDate().difference(checkIn.toDate());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "$hours h $minutes m";
  }
}
