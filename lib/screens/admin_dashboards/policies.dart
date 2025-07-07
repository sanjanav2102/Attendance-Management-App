import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  final CollectionReference policiesRef = FirebaseFirestore.instance.collection('policies');
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userRole = prefs.getString('userRole') ?? 'employee');
  }

  void _showPolicyDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = doc?.data() as Map<String, dynamic>? ?? {};

    final nameController = TextEditingController(text: data['policyName'] ?? '');
    final descController = TextEditingController(text: data['policyDescription'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Policy' : 'Add Policy'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Policy Name')),
              SizedBox(height: 8,),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Policy Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final now = Timestamp.now();
              final policyData = {
                'policyName': nameController.text.trim(),
                'policyDescription': descController.text.trim(),
                'updatedOn': now,
                'updatedBy': 'admin',
              };

              if (isEdit) {
                await doc!.reference.update(policyData);
              } else {
                await policiesRef.add({
                  ...policyData,
                  'createdOn': now,
                  'createdBy': 'admin',
                });
              }
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deletePolicy(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Policies', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton(
        onPressed: () => _showPolicyDialog(),
        backgroundColor: const Color(0xFF9D0B22),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: policiesRef.orderBy('updatedOn', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              bool showDetails = false;

              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['policyName'] ?? 'Unnamed',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (userRole == 'admin')
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showPolicyDialog(doc: doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deletePolicy(doc),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Description
                          Text(
                            data['policyDescription'] ?? '-',
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 8),

                          // Toggle Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(
                                showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.grey[700],
                              ),
                              onPressed: () {
                                setInnerState(() => showDetails = !showDetails);
                              },
                            ),
                          ),

                          // Extra Details (toggle visibility)
                          if (showDetails) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text("Created By: ${data['createdBy'] ?? '-'}"),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text("Created On: ${_formatTimestamp(data['createdOn'])}"),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.edit_note, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text("Updated By: ${data['updatedBy'] ?? '-'}"),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.update, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text("Updated On: ${_formatTimestamp(data['updatedOn'])}"),
                              ],
                            ),
                          ]
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
