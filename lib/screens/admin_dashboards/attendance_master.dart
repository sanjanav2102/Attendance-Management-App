import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  void _updateStatus(String docId, String status) async {
    await firestore.collection('attendance').doc(docId).update({
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

  Future<void> _pickTimeAndUpdate(Map<String, dynamic> entry, {required bool isCheckIn}) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    DateTime newTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    Timestamp? newCheckIn = isCheckIn ? Timestamp.fromDate(newTime) : entry['checkInTime'];
    Timestamp? newCheckOut = isCheckIn ? entry['checkOutTime'] : Timestamp.fromDate(newTime);

    if (newCheckIn != null && newCheckOut != null && newCheckOut.toDate().isBefore(newCheckIn.toDate())) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid Time"),
          content: const Text("Check-out time must be after check-in time."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    await firestore.collection('attendance').doc(entry['docId']).update({
      if (isCheckIn) 'checkInTime': Timestamp.fromDate(newTime) else 'checkOutTime': Timestamp.fromDate(newTime),
      'updatedOn': Timestamp.now(),
      'updatedBy': 'admin',
    });

    fetchAttendance();
  }

  Future<void> _showDateRangeDialog() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    _generatePdf(picked.start, picked.end);
  }

  Future<void> _generatePdf(DateTime start, DateTime end) async {
    final tableData = await _getAttendanceDataForPdf(start, end);
    print('Table Data for PDF: $tableData'); // Debug log

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Attendance PDF Preview')),
            body: PdfPreview(
              build: (format) async {
                final pdf = pw.Document();

                pdf.addPage(
                  pw.MultiPage(
                    build: (context) => [
                      pw.Text('Attendance Report: ${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}'),
                      pw.SizedBox(height: 12),
                      pw.Table.fromTextArray(
                        headers: ['Name', 'Date', 'Check-In', 'Check-Out', 'Hours', 'Status'],
                        data: tableData,
                      ),
                    ],
                  ),
                );

                return pdf.save();
              },
            ),
          ),
        ),
      );
    } catch (e, stack) {
      print('PDF generation failed: $e');
      print('Stack trace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generation failed: $e')),
      );
    }
  }

  Future<List<List<String>>> _getAttendanceDataForPdf(DateTime start, DateTime end) async {
    final List<List<String>> rows = [];
    final userSnap = await firestore.collection('user').get();

    for (var userDoc in userSnap.docs) {
      final user = userDoc.data();
      final userId = user['userId'].toString();
      final name = (user['name'] ?? '-').toString();


      for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final docId = "${userId}_${DateFormat('ddMMyyyy').format(d)}";
        final attendanceDoc = await firestore.collection('attendance').doc(docId).get();

        String checkIn = '-';
        String checkOut = '-';
        String hoursWorked = '-';
        String status = 'Absent';

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data()!;
          final Timestamp? checkInTS = data['checkInTime'];
          final Timestamp? checkOutTS = data['checkOutTime'];

          if (checkInTS != null) {
            checkIn = DateFormat('hh:mm a').format(checkInTS.toDate());
          }
          if (checkOutTS != null) {
            checkOut = DateFormat('hh:mm a').format(checkOutTS.toDate());
          }
          if (checkInTS != null && checkOutTS != null) {
            final duration = checkOutTS.toDate().difference(checkInTS.toDate());
            final hours = duration.inHours;
            final minutes = duration.inMinutes % 60;
            hoursWorked = "$hours h $minutes m";
          }

          status = data['status'] ?? 'Absent';
        }

        rows.add([
          name.toString(),
          DateFormat('dd-MM-yyyy').format(d),
          checkIn.toString(),
          checkOut.toString(),
          hoursWorked.toString(),
          status.toString(),
        ]);

      }
    }

    return rows;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _showDateRangeDialog,
          ),
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
            DataColumn(label: Text("Check-In")),
            DataColumn(label: Text("Check-Out")),
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
              DataCell(
                InkWell(
                  onTap: () => _pickTimeAndUpdate(entry, isCheckIn: true),
                  child: Text(_formatTime(entry['checkInTime'])),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _pickTimeAndUpdate(entry, isCheckIn: false),
                  child: Text(_formatTime(entry['checkOutTime'])),
                ),
              ),
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