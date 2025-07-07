import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CodesMasterScreen extends StatefulWidget {
  const CodesMasterScreen({super.key});

  @override
  State<CodesMasterScreen> createState() => _CodesMasterScreenState();
}

class _CodesMasterScreenState extends State<CodesMasterScreen> {
  final CollectionReference codesRef = FirebaseFirestore.instance.collection('codes_master');
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

  void _showCodeDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = doc?.data() as Map<String, dynamic>? ?? {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final shortDescController = TextEditingController(text: data['shortDescription'] ?? '');
    final longDescController = TextEditingController(text: data['longDescription'] ?? '');
    final typeController = TextEditingController(text: data['type'] ?? '');
    bool isActive = data['active'] ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Code' : 'Add Code'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                SizedBox(height: 7,),
                TextField(controller: shortDescController, decoration: const InputDecoration(labelText: 'Short Description')),
                SizedBox(height: 7,),
                TextField(controller: longDescController, decoration: const InputDecoration(labelText: 'Long Description')),
                SizedBox(height: 7,),
                TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type')),
                SizedBox(height: 7,),
                SwitchListTile(
                  title: const Text("Active"),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final now = Timestamp.now();
                final codeData = {
                  'name': nameController.text.trim(),
                  'shortDescription': shortDescController.text.trim(),
                  'longDescription': longDescController.text.trim(),
                  'type': typeController.text.trim(),
                  'active': isActive,
                  'updatedOn': now,
                  'updatedBy': 'admin',
                };

                if (isEdit) {
                  await doc!.reference.update(codeData);
                } else {
                  await codesRef.add({
                    ...codeData,
                    'createdOn': now,
                    'createdBy': 'admin',
                  });
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? "Update" : "Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCode(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes Master', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton(
        onPressed: () => _showCodeDialog(),
        backgroundColor: const Color(0xFF9D0B22),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: codesRef.orderBy('updatedOn', descending: true).snapshots(),
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
                builder: (context, setInnerState) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                data['name'] ?? 'Unnamed',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (userRole == 'admin')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.lightBlue),
                                    onPressed: () => _showCodeDialog(doc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCode(doc),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Text("Short Desc: ${data['shortDescription'] ?? ''}"),
                        Text("Long Desc: ${data['longDescription'] ?? ''}"),
                        Text("Type: ${data['type'] ?? ''}"),
                        Text("Active: ${data['active'] ? 'Yes' : 'No'}"),

                        // Toggle
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

                        if (showDetails) ...[
                          const Divider(height: 20),
                          Text("Created By: ${data['createdBy'] ?? 'admin@company.com'}"),
                          Text("Created On: ${_formatTimestamp(data['createdOn'])}"),
                          Text("Updated By: ${data['updatedBy'] ?? '-'}"),
                          Text("Updated On: ${_formatTimestamp(data['updatedOn'])}"),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
