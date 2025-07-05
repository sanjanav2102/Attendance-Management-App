import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> attendanceList = [];
  List<String> statuses = ['Present', 'Absent', 'Half Day'];

  @override
  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }


  Future<void> fetchAttendance() async {
    attendanceList.clear();
    final usersSnapshot = await firestore.collection('user').get();

    for (var userDoc in usersSnapshot.docs) {
      final user = userDoc.data();
      final userId = user['userId'].toString();
      final docId = "${userId}_${DateFormat('ddMMyyyy').format(selectedDate)}";
      final attendanceDoc = await firestore.collection('attendance').doc(docId).get();

      Map<String, dynamic> attendance = {
        'name': user['name'],
        'userId': user['userId'],
        'email': userDoc.id,
        'role': user['role'],
        'status': user['role'] == 'admin' ? 'Present' : 'Absent',
        'checkInTime': null,
        'checkOutTime': null,
        'docId': docId,
      };

      if (attendanceDoc.exists) {
        final data = attendanceDoc.data()!;
        attendance['status'] = data['status'] ?? 'Absent';
        attendance['checkInTime'] = data['checkInTime'];
        attendance['checkOutTime'] = data['checkOutTime'];
      }

      attendanceList.add(attendance);
    }

    setState(() {});
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "-";
    return DateFormat('hh:mm a').format(ts.toDate());
  }

  String _calculateWorkedHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return "-";
    final duration = checkOut.toDate().difference(checkIn.toDate());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "$hours h $minutes m";
  }

  void _updateStatus(String docId, String status) {
    firestore.collection('attendance').doc(docId).update({
      'status': status,
      'updatedBy': 'admin',
      'updatedOn': Timestamp.now(),
    });
    fetchAttendance();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
    title: const Text('Attendance Manager'),
    actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          )
        ],
      ),
      body: attendanceList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Hours Worked")),
            DataColumn(label: Text("Edit")),
          ],
          rows: attendanceList.map((entry) {
            final isAdmin = entry['role'] == 'admin';
            final currentStatus = entry['status'] ?? 'Absent';
            return DataRow(cells: [
              DataCell(Text(entry['name'] ?? '')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentStatus == 'Present'
                      ? Colors.green
                      : currentStatus == 'Half Day'
                      ? Colors.orange
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentStatus,
                  style: const TextStyle(color: Colors.white),
                ),
              )),
              DataCell(Text(_calculateWorkedHours(entry['checkInTime'], entry['checkOutTime']))),
              DataCell(
                isAdmin
                    ? const Icon(Icons.lock, color: Colors.grey)
                    : IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        String dropdownValue = currentStatus;
                        return AlertDialog(
                          title: const Text("Update Status"),
                          content: DropdownButtonFormField<String>(
                            value: dropdownValue,
                            items: statuses
                                .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) dropdownValue = val;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _updateStatus(entry['docId'], dropdownValue);
                                Navigator.of(context).pop();
                              },
                              child: const Text("Update"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              )
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
