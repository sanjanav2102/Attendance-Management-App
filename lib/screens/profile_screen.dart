import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditable = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  String selectedGender = "Male";
  String? email;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    dobController = TextEditingController();
    fetchUserData();
  }


  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('userEmail');


    if (email == null) {
      print("Email not there");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found in session.')),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('user').doc(email).get();

    if (doc.exists) {
      userData = doc.data();

      final rawDob = userData!['dob'];
      String formattedDob = '';
      if (rawDob is Timestamp) {
        formattedDob = DateFormat('dd-MM-yyyy').format(rawDob.toDate());
      } else if (rawDob is String) {
        formattedDob = rawDob;
      }

      nameController = TextEditingController(text: userData!['name'] ?? '');
      phoneController = TextEditingController(text: userData!['phone'] ?? '');
      addressController = TextEditingController(text: userData!['address'] ?? '');
      dobController = TextEditingController(text: formattedDob);
      selectedGender = (userData!['gender'] ?? 'Male').toString().capitalizeFirstLetter();

      setState(() => isLoading = false);
    }

    else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<void> saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('user').doc(email).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'gender': selectedGender,
        'dob': dobController.text,
      });

      setState(() => isEditable = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Widget buildEditableField(String label, TextEditingController controller, {bool enabled = true, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        enabled: enabled,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
        ),
        validator: (value) => value == null || value.isEmpty ? '$label cannot be empty' : null,
      ),
    );
  }


  Widget buildReadOnlyField(String label, String value) {
    return buildEditableField(label, TextEditingController(text: value), enabled: false);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dobController.text.isNotEmpty
          ? DateFormat('dd-MM-yyyy').parse(dobController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF9D0B22);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: Icon(isEditable ? Icons.cancel : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() => isEditable = !isEditable);
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No profile data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: const AssetImage('assets/emp_avatar.png'),
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildEditableField("Name", nameController, enabled: isEditable),
                      buildReadOnlyField("Email", userData!['email'] ?? ''),
                      buildReadOnlyField("Designation", userData!['designation'] ?? ''),
                      buildEditableField("Address", addressController, enabled: isEditable),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          onChanged: isEditable ? (val) => setState(() => selectedGender = val!) : null,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: const TextStyle(color: Colors.black),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isEditable ? Colors.white : Colors.grey[200],
                          ),
                          items: const [
                            DropdownMenuItem(value: "Male", child: Text("Male",style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(value: "Female", child: Text("Female",style: TextStyle(color: Colors.black))),
                          ],
                        ),

                      ),
                      buildEditableField("DOB", dobController, enabled: isEditable, onTap: isEditable ? pickDate : null),
                      buildEditableField("Phone", phoneController, enabled: isEditable),
                      buildReadOnlyField("Role", userData!['role'] ?? ''),
                      const SizedBox(height: 12),
                      if (isEditable)
                        ElevatedButton(
                          onPressed: saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
extension StringCasingExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
