import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _workingDateController = TextEditingController();
  final TextEditingController _leaveDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _workingDate;
  DateTime? _leaveDate;
  String? _selectedLeaveType;
  String? _leaveDescription;
  String? _userId;
  List<Map<String, dynamic>> _submittedLeaves = [];

  List<DropdownMenuItem<String>> _leaveTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchLeaveTypes();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('loggedInUserId');
    if (_userId != null) {
      _fetchExistingLeaves();
    }
  }

  Future<void> _fetchLeaveTypes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('codes_master')
        .where('type', isEqualTo: 'leave')
        .where('active', isEqualTo: true)
        .get();

    setState(() {
      _leaveTypes = snapshot.docs.map((doc) {
        return DropdownMenuItem<String>(
          value: doc['name'],
          child: Text(doc['name']),
        );
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _fetchLeaveDescription(String leaveType) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('codes_master')
        .where('type', isEqualTo: 'leave')
        .where('name', isEqualTo: leaveType)
        .limit(1)
        .get();

    setState(() {
      _leaveDescription =
      snapshot.docs.isNotEmpty ? snapshot.docs.first['LongDescription'] : null;
    });
  }

  Future<void> _pickDate({required Function(DateTime) onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _fetchExistingLeaves() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('leaves')
        .where('userId', isEqualTo: int.parse(_userId!))
        .orderBy('appliedOn', descending: true)
        .get();

    setState(() {
      _submittedLeaves = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> _applyLeave() async {
    if (_formKey.currentState!.validate() && _selectedLeaveType != null &&
        _userId != null) {
      if (_selectedLeaveType == 'comp_off' &&
          (_workingDate == null || _leaveDate == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please select working and leave dates.")));
        return;
      }

      if (_selectedLeaveType != 'comp_off' &&
          (_startDate == null || _endDate == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please select start and end dates.")));
        return;
      }

      try {
        final now = DateTime.now();
        final leaveData = {
          'userId': int.parse(_userId!),
          'leaveType': _selectedLeaveType!,
          'reason': _reasonController.text.trim(),
          'status': 'Pending',
          'appliedOn': Timestamp.fromDate(now),
          'createdBy': int.parse(_userId!),
          'createdOn': Timestamp.fromDate(now),
          'updatedOn': Timestamp.fromDate(now),
          'updatedBy': _userId!,
          'reasonForReject': '',
          'reasonFromAdmin': '',
        };

        if (_selectedLeaveType == 'comp_off') {
          leaveData['dateOfWorking'] = Timestamp.fromDate(_workingDate!);
          leaveData['dateOfLeave'] = Timestamp.fromDate(_leaveDate!);
        } else {
          leaveData['startDate'] = Timestamp.fromDate(_startDate!);
          leaveData['endDate'] = Timestamp.fromDate(_endDate!);
        }

        final docRef =
        await FirebaseFirestore.instance.collection('leaves').add(leaveData);

        leaveData['id'] = docRef.id;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Leave applied successfully")),
        );

        setState(() {
          _submittedLeaves.insert(0, leaveData);
          _formKey.currentState!.reset();
          _startDate = null;
          _endDate = null;
          _selectedLeaveType = null;
          _workingDate = null;
          _leaveDate = null;
          _leaveDescription = null;
          _workingDateController.clear();
          _leaveDateController.clear();
        });
      } catch (e) {
        debugPrint("Firestore Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to apply leave: $e")),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    int _leaveDays = 0;
    if (_selectedLeaveType == 'comp_off') {
      _leaveDays = 1;
    } else if (_selectedLeaveType == 'Half Day') {
      _leaveDays =
      1; // Half day considered as 1 calendar day, half pay logic can be handled elsewhere
    } else if (_startDate != null && _endDate != null) {
      _leaveDays = _endDate!.difference(_startDate!).inDays + 1;
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text(
              'Apply Leave', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF9D0B22)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Leave Type', border: OutlineInputBorder()),
                items: _leaveTypes,
                value: _selectedLeaveType,
                onChanged: (value) {
                  setState(() {
                    _selectedLeaveType = value;
                    _leaveDescription = null;
                    _startDate = null;
                    _endDate = null;
                    _workingDate = null;
                    _leaveDate = null;
                    _workingDateController.clear();
                    _leaveDateController.clear();
                  });
                  _fetchLeaveDescription(value!);
                },
                validator: (value) =>
                value == null
                    ? 'Select leave type'
                    : null,
              ),
              if (_leaveDescription != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_leaveDescription!,
                        style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 16),

              if (_selectedLeaveType == 'comp_off') ...[
                TextFormField(
                  controller: _workingDateController,
                  readOnly: true,
                  onTap: () =>
                      _pickDate(onPicked: (picked) {
                        setState(() {
                          _workingDate = picked;
                          _workingDateController.text =
                              DateFormat('dd MMM yyyy').format(picked);
                        });
                      }),
                  decoration: const InputDecoration(
                      labelText: 'Date of Working',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                  value!.isEmpty ? 'Select working date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _leaveDateController,
                  readOnly: true,
                  onTap: () =>
                      _pickDate(onPicked: (picked) {
                        setState(() {
                          _leaveDate = picked;
                          _leaveDateController.text =
                              DateFormat('dd MMM yyyy').format(picked);
                        });
                      }),
                  decoration: const InputDecoration(
                      labelText: 'Date of Leave', border: OutlineInputBorder()),
                  validator: (value) =>
                  value!.isEmpty ? 'Select leave date' : null,
                ),
              ] else
                if (_selectedLeaveType == 'Half Day') ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Leave Date', border: OutlineInputBorder()),
                    child: Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now())),
                  ),
                  const SizedBox(height: 16),
                ] else
                  ...[
                    InkWell(
                      onTap: () =>
                          _pickDate(onPicked: (d) =>
                              setState(() =>
                              _startDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder()),
                        child: Text(_startDate != null
                            ? DateFormat('dd MMM yyyy').format(_startDate!)
                            : 'Pick a start date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () =>
                          _pickDate(onPicked: (d) =>
                              setState(() =>
                              _endDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder()),
                        child: Text(_endDate != null
                            ? DateFormat('dd MMM yyyy').format(_endDate!)
                            : 'Pick an end date'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

              if (_selectedLeaveType != null &&
                  (_selectedLeaveType == 'comp_off' ||
                      _selectedLeaveType == 'Half Day' ||
                      (_startDate != null && _endDate != null)))
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Leave Duration: $_leaveDays day${_leaveDays > 1
                        ? 's'
                        : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                    labelText: 'Reason', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter reason' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Apply Leave',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D0B22),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                onPressed: _applyLeave,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Submitted Leaves',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._submittedLeaves.map((leave) {
                final status = leave['status'] ?? 'Pending';
                final color = status == 'Approved'
                    ? Colors.green[100]
                    : status == 'Rejected'
                    ? Colors.red[100]
                    : Colors.orange[100];
                final label = status;
                final reason = leave['reasonFromAdmin'] ?? '';

                String dateRange = '';
                int duration = 1;
                if (leave['leaveType'] == 'comp_off') {
                  dateRange =
                  'Leave: ${DateFormat('dd MMM').format(
                      (leave['dateOfLeave'] as Timestamp)
                          .toDate())} | Worked: ${DateFormat('dd MMM').format(
                      (leave['dateOfWorking'] as Timestamp).toDate())}';
                } else if (leave['leaveType'] == 'Half Day') {
                  final date = DateFormat('dd MMM yyyy').format(
                      (leave['appliedOn'] as Timestamp).toDate());
                  dateRange = 'Date: $date';
                } else {
                  final start = (leave['startDate'] as Timestamp).toDate();
                  final end = (leave['endDate'] as Timestamp).toDate();
                  duration = end
                      .difference(start)
                      .inDays + 1;
                  dateRange =
                  '${DateFormat('dd MMM').format(start)} - ${DateFormat(
                      'dd MMM').format(end)}';
                }

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('${leave['leaveType']} ($dateRange)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason: ${leave['reason']}'),
                        Text('Days: $duration'),
                        if (reason.isNotEmpty)
                          Text('Admin Note: $reason',
                              style:
                              const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(label,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList()
            ],
          ),
        ),
      ),
    );
  }
}