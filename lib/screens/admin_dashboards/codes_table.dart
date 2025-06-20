import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CodesMasterScreen extends StatefulWidget {
  const CodesMasterScreen({super.key});

  @override
  State<CodesMasterScreen> createState() => _CodesMasterScreenState();
}

class _CodesMasterScreenState extends State<CodesMasterScreen> {
  final CollectionReference codesRef = FirebaseFirestore.instance.collection('codes_master');

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
                TextField(controller: shortDescController, decoration: const InputDecoration(labelText: 'shortDescription')),
                TextField(controller: longDescController, decoration: const InputDecoration(labelText: 'longDescription')),
                TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Type')),
                SwitchListTile(
                  title: const Text("Active"),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final codeData = {
                  'name': nameController.text.trim(),
                  'shortDescription': shortDescController.text.trim(),
                  'longDescription': longDescController.text.trim(),
                  'type': typeController.text.trim(),
                  'active': isActive,
                  'updatedOn': Timestamp.now(),
                  'updatedBy': 'admin',
                };

                if (isEdit) {
                  await doc!.reference.update(codeData);
                } else {
                  await codesRef.add({
                    ...codeData,
                    'createdOn': Timestamp.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes Master', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCodeDialog(),
        backgroundColor: const Color(0xFF9D0B22),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['name'] ?? 'Unnamed',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 18),),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Short Desc: ${data['shortDescription'] ?? ''}"),
                      Text("Long Desc: ${data['longDescription'] ?? ''}"),
                      Text("Type: ${data['type'] ?? ''}"),
                      Text("Active: ${data['active'] ? 'Yes' : 'No'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit,
                        color: Colors.lightBlue,), onPressed: () => _showCodeDialog(doc: doc)),
                      IconButton(icon: const Icon(Icons.delete,
                        color: Colors.red,), onPressed: () => _deleteCode(doc)),
                    ],
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

