import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveMasterScreen extends StatefulWidget {
  const LeaveMasterScreen({super.key});

  @override
  State<LeaveMasterScreen> createState() => _LeaveMasterScreenState();
}

class _LeaveMasterScreenState extends State<LeaveMasterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getLeaveTypeName(String leaveTypeCode) async {
    final snapshot = await _firestore
        .collection('codes_master')
        .where('type', isEqualTo: 'leaveType')
        .where('name', isEqualTo: leaveTypeCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['longDescription'] ?? leaveTypeCode;
    } else {
      return leaveTypeCode;
    }
  }

  void updateLeaveStatus(String docId, String status, String reasonFromAdmin) async {
    final updateData = {
      'status': status,
      'updatedBy': 'Admin',
      'updatedOn': DateTime.now(),
      'reasonFromAdmin': reasonFromAdmin,
    };

    await _firestore.collection('leaves').doc(docId).update(updateData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Leave $status')),
    );
  }

  void showDecisionDialog(String docId, String status) {
    final TextEditingController reasonController = TextEditingController();
    final isReject = status == 'Rejected';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReject ? 'Reject Leave' : 'Approve Leave'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'Reason for ${isReject ? 'Rejection' : 'Approval'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              updateLeaveStatus(docId, status, reasonController.text);
              Navigator.of(ctx).pop();
            },
            child: Text(status),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('leaves').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading data.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return FutureBuilder<String>(
                future: getLeaveTypeName(data['leaveType']),
                builder: (context, typeSnapshot) {
                  final leaveTypeName = typeSnapshot.data ?? data['leaveType'];
                  final status = data['status'] ?? 'Pending';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User ID: ${data['userId']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Leave Type: $leaveTypeName"),
                          if (leaveTypeName == 'Comp Off')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date of Working: ${data['dateOfWorking']?.toDate()?.toLocal().toString().split(' ')[0] ?? ''}"),
                                Text("Date of Leave: ${data['dateOfLeave']?.toDate()?.toLocal().toString().split(' ')[0] ?? ''}"),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Start Date: ${data['startDate']?.toDate()?.toLocal().toString().split(' ')[0] ?? ''}"),
                                Text("End Date: ${data['endDate']?.toDate()?.toLocal().toString().split(' ')[0] ?? ''}"),
                              ],
                            ),
                          Text("Reason: ${data['reason'] ?? ''}"),
                          Text("Status: $status"),
                          if ((data['reasonFromAdmin']?.isNotEmpty ?? false))
                            Text("Note from Admin: ${data['reasonFromAdmin']}", style: const TextStyle(color: Colors.deepPurple)),
                          const SizedBox(height: 10),
                          if (status == 'Pending')
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  label: const Text("Approve"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () => showDecisionDialog(docId, 'Approved'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.close),
                                  label: const Text("Reject"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => showDecisionDialog(docId, 'Rejected'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
