import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveStatusScreen extends StatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  State<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  int? _userId;
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchLeaves();
  }

  Future<void> _loadUserIdAndFetchLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('loggedInUserId');

    try {
      if (storedUserId == null) throw "User ID not found in shared preferences";

      _userId = int.parse(storedUserId);

      final snapshot = await FirebaseFirestore.instance
          .collection('leaves')
          .where('userId', isEqualTo: _userId)
          .orderBy('appliedOn', descending: true)
          .get();

      setState(() {
        _leaves = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print("❌ Error fetching leaves: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load leaves: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green[100]!;
      case 'Rejected':
        return Colors.red[100]!;
      default:
        return Colors.orange[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('My Leave Status', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _leaves.isEmpty
            ? const Center(child: Text('No leaves found.'))
            : ListView.builder(
          itemCount: _leaves.length,
          itemBuilder: (context, index) {
            final leave = _leaves[index];
            final status = leave['status'] ?? 'Pending';
            final reason = leave['reasonFromAdmin'] ?? '';
            final leaveType = leave['leaveType'];
            final appliedOn =
            (leave['appliedOn'] as Timestamp).toDate();
            String dateRange = '';

            if (leaveType == 'comp_off') {
              dateRange =
              'Worked: ${DateFormat('dd MMM').format((leave['dateOfWorking'] as Timestamp).toDate())}\nLeave: ${DateFormat('dd MMM').format((leave['dateOfLeave'] as Timestamp).toDate())}';
            } else {
              dateRange =
              '${DateFormat('dd MMM').format((leave['startDate'] as Timestamp).toDate())} - ${DateFormat('dd MMM').format((leave['endDate'] as Timestamp).toDate())}';
            }

            return Card(
              color: _getStatusColor(status),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leave Type: $leaveType',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Date: $dateRange'),
                    const SizedBox(height: 4),
                    Text('Reason: ${leave['reason']}'),
                    const SizedBox(height: 4),
                    Text('Applied On: ${DateFormat('dd MMM yyyy').format(appliedOn)}'),
                    const SizedBox(height: 4),
                    Text('Status: $status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: status == 'Approved'
                                ? Colors.green
                                : status == 'Rejected'
                                ? Colors.red
                                : Colors.orange)),
                    if (reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Admin Note: $reason',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.deepPurple)),
                      )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
