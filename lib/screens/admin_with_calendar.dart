import 'dart:convert';

import 'package:attendanceapp/screens/admin_dashboards/leave_requests.dart';
import 'package:attendanceapp/screens/admin_dashboards/policies.dart';
import 'package:attendanceapp/screens/leave_calander.dart';
import 'package:attendanceapp/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../themes/theme_provider.dart';
import 'admin_dashboards/attendance_master.dart';
import 'admin_dashboards/codes_table.dart';
import 'admin_dashboards/employee_master.dart';
import 'admin_dashboards/qr_code_generator.dart';
import 'logout_screen.dart';



class AdminHomeWithCalendar extends StatefulWidget {
  const AdminHomeWithCalendar({super.key});

  @override
  State<AdminHomeWithCalendar> createState() => _AdminHomeWithCalendarState();
}

class _AdminHomeWithCalendarState extends State<AdminHomeWithCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _holidays = {};
  Map<DateTime, List<String>> _absentMap = {};
  Set<DateTime> _fullPresentDates = {};
  Set<DateTime> _partialAbsentDates = {};
  AppThemeMode _selectedMode = AppThemeMode.system;

  String _weather = "Loading...";
  String _temperature = "--";
  String _city = "Trivandrum";



  final List<Map<String, dynamic>> menuItems = const [
    {
      "icon": Icons.people,
      "label": "Employee Master",
      "content": "View Employee Details"
    },
    {
      "icon": Icons.date_range_sharp,
      "label": "Attendance",
      "content": "View attendance details"
    },
    {
      "icon": Icons.calendar_month_sharp,
      "label": "Calendar",
      "content": "Leave Calendar"
    },
    {
      "icon": Icons.request_page,
      "label": "Requests",
      "content": "Leave Requests"
    },
    {
      "icon": Icons.table_chart_outlined,
      "label": "Codes",
      "content": "View codes"
    },
    {"icon": Icons.qr_code_sharp, "label": "QR Code", "content": "Generate QR Code"},
    {"icon": Icons.local_police_rounded, "label": "Policies", "content": "View Policies"},
  ];


  @override
  void initState() {
    super.initState();
    _loadHolidays();
    _loadAttendance();
    _fetchWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedMode = Provider.of<ThemeProvider>(context, listen: false).appThemeMode;
      });
    });
  }

  Future<void> _fetchWeather() async {
    final url = Uri.parse("https://api.weatherapi.com/v1/current.json?key=4cfd939aacbd4e068e2105146250607&q=$_city");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _weather = data['current']['condition']['text'];
        _temperature = data['current']['temp_c'].toString() + "°C";
      });
    } else {
      setState(() => _weather = "Unable to fetch weather");
    }
  }


  Future<void> _loadHolidays() async {
    final snapshot = await FirebaseFirestore.instance.collection(
        'leave_calendar').get();
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
    _absentMap.clear();
    _partialAbsentDates.clear();
    _fullPresentDates.clear();

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .get();
    Map<DateTime, List<String>> tempAbsentMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final name = data['name'] ?? '';
      final timestamp = data['date'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        final key = DateTime(date.year, date.month, date.day);

        if (status != 'Present') {
          tempAbsentMap.putIfAbsent(key, () => []).add(name);
        }
      }
    }
    setState(() {
      _absentMap = tempAbsentMap;
      for (var day in tempAbsentMap.keys) {
        _partialAbsentDates.add(day);
      }

      final allDates = snapshot.docs.map((doc) {
        final ts = doc['date'] as Timestamp;
        final dt = ts.toDate();
        return DateTime(dt.year, dt.month, dt.day);
      }).toSet();

      for (var day in allDates) {
        if (!_partialAbsentDates.contains(day)) {
          _fullPresentDates.add(day);
        }
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final events = _holidays[key]?.toList() ?? [];
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
        title: const Text('Hi Admin!'),
      ),
      drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF9D0B22)),
              accountName: Text('Admin'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Center(child: Icon(
                    Icons.person, size: 40, color: Color(0xFF9D0B22))),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF9D0B22)),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6, color: Color(0xFF9D0B22)),
              title: const Text("Theme"),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<AppThemeMode>(
                  value: _selectedMode,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  dropdownColor: Theme.of(context).cardColor,
                  style: Theme.of(context).textTheme.bodyMedium,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.system,
                      child: Text("System"),
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
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF9D0B22)),
              title: const Text("Logout"),
              onTap: () =>
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LogoutScreen())),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.network("https://cdn.weatherapi.com/weather/64x64/day/116.png", height: 48),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$_city Weather", style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                        Text("$_weather | $_temperature", style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
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
                                ...events.map((e) => Text(
                                  "${e['holidayName'] ?? e['status']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
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
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF9D0B22),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(color: Colors.red),
                      weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final key = DateTime(date.year, date.month, date.day);
                        if (date.weekday == DateTime.saturday ||
                            date.weekday == DateTime.sunday) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          );
                        } else if (_holidays.containsKey(key)) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          );
                        }
                        return null;
                      },
                      defaultBuilder: (context, date, _) {
                        final key = DateTime(date.year, date.month, date.day);
                        final isPresent = _fullPresentDates.contains(key);
                        final isAbsent = _partialAbsentDates.contains(key);

                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isAbsent
                                ? Colors.red.withOpacity(0.2)
                                : isPresent
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            children: [
                              Center(child: Text('${date.day}')),
                              if (_absentMap.containsKey(key))
                                Positioned(
                                  bottom: 2,
                                  left: 2,
                                  right: 2,
                                  child: Text(
                                    _absentMap[key]!.join(', '),
                                    style: const TextStyle(
                                        fontSize: 8, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final label = menuItems[index]['label'];
                  return GestureDetector(
                    onTap: () {
                      if (label == 'Employee Master') {
                        Navigator.push(context, MaterialPageRoute(builder: (
                            _) => const EmployeeMasterScreen()));
                      } else if (label == 'Attendance') {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AdminAttendanceScreen()));
                      } else if (label == 'Calendar') {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const LeaveCalendarScreen()));
                      } else if (label == 'Codes') {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const CodesMasterScreen()));
                      } else if (label == 'Requests') {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const LeaveMasterScreen()));
                      }
                      else if (label == 'QR Code') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QRCodeGeneratorScreen(userEmail: 'admin@company.com')),
                        );
                      }
                      else if (label == 'Policies') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PolicyScreen()),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // dynamic background
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(menuItems[index]['icon'], size: 40, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 10),
                          Text(
                            menuItems[index]['label'],
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            menuItems[index]['content'],
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  );
                },
                childCount: menuItems.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}