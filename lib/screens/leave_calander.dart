import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class LeaveCalendarScreen extends StatefulWidget {
  const LeaveCalendarScreen({super.key});

  @override
  State<LeaveCalendarScreen> createState() => _LeaveCalendarScreenState();
}

class _LeaveCalendarScreenState extends State<LeaveCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _holidays = {};

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    final snapshot = await FirebaseFirestore.instance.collection('leave_calendar').get();

    Map<DateTime, List<Map<String, dynamic>>> loaded = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      DateTime date = (data['holidayDate'] as Timestamp).toDate();
      final key = DateTime(date.year, date.month, date.day);
      loaded.putIfAbsent(key, () => []).add({...data, 'id': doc.id});
    }

    setState(() {
      _holidays = loaded;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final events = _holidays[key]?.toList() ?? [];

    if (day.weekday == DateTime.saturday) {
      events.add({'holidayName': 'Saturday', 'type': 'weekend'});
    } else if (day.weekday == DateTime.sunday) {
      events.add({'holidayName': 'Sunday', 'type': 'weekend'});
    }

    return events;
  }


  void _showAddOrEditHolidayDialog({Map<String, dynamic>? existingHoliday}) {
    final nameController = TextEditingController(text: existingHoliday?['holidayName'] ?? '');
    DateTime selectedDate = existingHoliday?['holidayDate']?.toDate() ?? _focusedDay;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingHoliday == null ? "Add Holiday" : "Edit Holiday"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Holiday Name'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: const Text("Pick Date"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                if (existingHoliday == null) {
                  await FirebaseFirestore.instance.collection('leave_calendar').add({
                    'holidayName': nameController.text.trim(),
                    'holidayDate': Timestamp.fromDate(selectedDate),
                    'createdBy': 'admin',
                    'createdOn': Timestamp.now(),
                    'updatedBy': 'admin',
                    'updatedOn': Timestamp.now(),
                    'active': 'Yes',
                  });
                } else {
                  await FirebaseFirestore.instance
                      .collection('leave_calendar')
                      .doc(existingHoliday['id'])
                      .update({
                    'holidayName': nameController.text.trim(),
                    'holidayDate': Timestamp.fromDate(selectedDate),
                    'updatedBy': 'admin',
                    'updatedOn': Timestamp.now(),
                  });
                }
                Navigator.pop(context);
                _loadHolidays();
              }
            },
            child: Text(existingHoliday == null ? "Add" : "Update"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _deleteHoliday(String docId) async {
    await FirebaseFirestore.instance.collection('leave_calendar').doc(docId).delete();
    _loadHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Calendar", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWeekend ? Colors.red : Colors.black,
                    ),
                  );
                }
                return null;
              },

            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay)
                  .map((e) => ListTile(
                title: Text("Holiday: ${e['holidayName']}"),
                trailing: e['type'] == 'weekend'
                    ? null
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddOrEditHolidayDialog(existingHoliday: e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteHoliday(e['id']),
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditHolidayDialog(),
        backgroundColor: const Color(0xFF9D0B22),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}