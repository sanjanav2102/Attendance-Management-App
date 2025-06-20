import 'package:attendanceapp/screens/admin_with_calendar.dart';
import 'package:attendanceapp/screens/employee_dashboards/leave_apply.dart';
import 'package:attendanceapp/screens/employee_dashboards/leave_status.dart';
import 'package:attendanceapp/screens/employee_dashboards/mark_attendance.dart';
import 'package:attendanceapp/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../screens/login_screen.dart';
import '../themes/theme_provider.dart';
import 'admin_dashboards/attendance_master.dart';
import 'admin_dashboards/codes_table.dart';
import 'admin_dashboards/employee_master.dart';
import 'admin_dashboards/leave_requests.dart';
import 'leave_calander.dart';
import 'logout_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final String email;
  const EmployeeDashboard({super.key, required this.email});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _holidays = {};
  Map<DateTime, String> _attendanceStatus = {};
  String userId = 'userId';
  String name = 'name';
  AppThemeMode _selectedMode = AppThemeMode.system;

  final List<Map<String, dynamic>> menuItems = const [
    {"icon": Icons.date_range_sharp, "label": "Attendance", "content": "View attendance details"},
    {"icon": Icons.request_page, "label": "Apply Leave", "content": "Leave Requests"},
    {"icon": Icons.calendar_view_day_sharp, "label": "Leave Status", "content": "View your leave status"},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300), () async {
      await _loadUserData();
      await _loadAttendance();
      await _loadHolidays();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedMode = Provider.of<ThemeProvider>(context, listen: false).appThemeMode;
      });
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      name = prefs.getString('userName') ?? '';
      print(userId);
    });
  }

  Future<void> _loadHolidays() async {
    final snapshot = await FirebaseFirestore.instance.collection('leave_calendar').get();
    Map<DateTime, List<Map<String, dynamic>>> loaded = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      DateTime date = (data['holidayDate'] as Timestamp).toDate();
      final key = DateTime(date.year, date.month, date.day);
      loaded.putIfAbsent(key, () => []).add(data);
    }
    setState(() {
      _holidays = loaded;
    });
  }

  Future<void> _loadAttendance() async {
    print("Loading attendance for userId: $userId");
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('userId', isEqualTo: int.tryParse(userId) ?? userId)
        .get();
    print("Found ${snapshot.docs.length} documents");

    Map<DateTime, String> statusMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] != null) {
        final dateParts = doc.id.split('_');
        if (dateParts.length >= 2) {
          final dateStr = dateParts[1];
          if (dateStr.length == 8) {
            final day = int.tryParse(dateStr.substring(0, 2));
            final month = int.tryParse(dateStr.substring(2, 4));
            final year = int.tryParse(dateStr.substring(4));
            if (day != null && month != null && year != null) {
              final date = DateTime(year, month, day);
              statusMap[DateTime(date.year, date.month, date.day)] = data['status'];
            }
          }
        }
      }
    }

    setState(() {
      _attendanceStatus = statusMap;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final events = _holidays[key]?.toList() ?? [];

    if (_attendanceStatus[key] == 'Absent') {
      events.add({'status': 'Absent'});
    }

    if (day.weekday == DateTime.saturday) {
      events.add({'holidayName': 'Saturday'});
    } else if (day.weekday == DateTime.sunday) {
      events.add({'holidayName': 'Sunday'});
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi Employee', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D0B22),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF9D0B22)),
              accountName: Text('Employee'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Center(child: Icon(Icons.person, size: 40, color: Color(0xFF9D0B22))),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF9D0B22)),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<AppThemeMode>(
                icon: Icon(Icons.change_circle_outlined),
                isExpanded: true,
                value: _selectedMode,
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text("System Default"),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text("Light"),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text("Dark"),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    Provider.of<ThemeProvider>(context, listen: false).setTheme(mode);
                    setState(() => _selectedMode = mode);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF9D0B22)),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LogoutScreen()));
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF0F0F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });

                  final events = _getEventsForDay(selected);
                  if (events.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Holiday Info"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${selected.day}-${selected.month}-${selected.year}"),
                            const SizedBox(height: 10),
                            ...events.map((e) => Text("${e['holidayName'] ?? e['status']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.red.shade300,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.redAccent),
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(4),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.redAccent),
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final key = DateTime(day.year, day.month, day.day);
                    final isAbsent = _attendanceStatus[key] == 'Absent';

                    return Container(
                      decoration: BoxDecoration(
                        color: isAbsent ? Colors.red.withOpacity(0.4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(4),
                      child: Text('${day.day}'),
                    );
                  },
                  markerBuilder: (context, date, events) {
                    final key = DateTime(date.year, date.month, date.day);
                    bool isHoliday = _holidays.containsKey(key);
                    bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

                    Color? dotColor;
                    if (isHoliday) {
                      dotColor = Colors.black;
                    } else if (isWeekend) {
                      dotColor = Colors.red;
                    }

                    if (dotColor != null) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        ),
                      );
                    }

                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final label = menuItems[index]['label'];
                  return GestureDetector(
                    onTap: () {
                      if (label == 'Attendance') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EmployeeAttendanceScreen(userId: userId, name: name),
                        ));
                      } else if (label == 'Apply Leave') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveApplicationScreen()));
                      } else if (label == 'Leave Status') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveStatusScreen()));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(menuItems[index]['icon'], size: 40, color: Color(0xFF9D0B22)),
                          const SizedBox(height: 10),
                          Text(
                            menuItems[index]['label'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            menuItems[index]['content'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
