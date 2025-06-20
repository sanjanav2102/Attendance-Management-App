import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeMasterScreen extends StatefulWidget {
  const EmployeeMasterScreen({super.key});

  @override
  State<EmployeeMasterScreen> createState() => _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends State<EmployeeMasterScreen> {
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('user');

  void _deleteEmployee(String docId) async {
    await userCollection.doc(docId).delete();
  }

  void _editEmployee(BuildContext context, Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        final userIdController = TextEditingController(text: data['userId'].toString());
        final nameController = TextEditingController(text: data['name']);
        final phoneController = TextEditingController(text: data['phone'].toString());
        final designationController = TextEditingController(text: data['designation']);
        final addressController = TextEditingController(text: data['address']);
        final genderController = TextEditingController(text: data['gender']);
        String selectedRole = data['role'] ?? 'employee';

        return AlertDialog(
          title: const Text("Edit Employee Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: designationController, decoration: const InputDecoration(labelText: 'Designation')),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'employee'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await userCollection.doc(docId).update({
                  'userId': userIdController.text.trim(),
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'designation': designationController.text.trim(),
                  'address': addressController.text.trim(),
                  'gender': genderController.text.trim(),
                  'role': selectedRole,
                  'updatedBy': 'admin',
                  'updatedOn': Timestamp.now(),
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _addEmployee() {
    showDialog(
      context: context,
      builder: (context) {
        final userIdController = TextEditingController();
        final emailController = TextEditingController();
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final designationController = TextEditingController();
        final addressController = TextEditingController();
        final genderController = TextEditingController();
        String selectedRole = 'employee';

        return AlertDialog(
          title: const Text("Add New Employee"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: userIdController, decoration: const InputDecoration(labelText: 'User ID')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: genderController, decoration: const InputDecoration(labelText: 'Gender')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: designationController, decoration: const InputDecoration(labelText: 'Designation')),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'employee'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await userCollection.doc(emailController.text.trim()).set({
                  'userId': userIdController.text.trim(),
                  'email': emailController.text.trim(),
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'gender': genderController.text.trim(),
                  'designation': designationController.text.trim(),
                  'role': selectedRole,
                  'address': addressController.text.trim(),
                  'createdBy': 'admin',
                  'createdOn': Timestamp.now(),
                  'updatedBy': 'admin',
                  'updatedOn': Timestamp.now(),
                  'password': 'default123',
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Master", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No employees found"));
          }

          final employees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final data = employees[index].data() as Map<String, dynamic>;
              final docId = employees[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.person_outline, color: Colors.red, size: 30),
                  title: Text(
                    "${data['name'] ?? '-'} | ${data['userId'] ?? '-'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  subtitle: Text(data['email'] ?? ''),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone: ${data['phone'] ?? '-'}", style: const TextStyle(fontSize: 15)),
                          Text("Designation: ${data['designation'] ?? '-'}"),
                          Text("Role: ${data['role'] ?? '-'}"),
                        ],
                      ),
                    ),
                    if (data['role'] == 'admin')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editEmployee(context, data, docId),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editEmployee(context, data, docId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEmployee(docId),
                          ),
                        ],
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        backgroundColor: const Color(0xFF9D0B22),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
