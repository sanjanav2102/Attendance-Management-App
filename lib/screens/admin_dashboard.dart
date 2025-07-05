import 'package:attendanceapp/screens/admin_dashboards/attendance_master.dart';
import 'package:attendanceapp/screens/admin_dashboards/codes_table.dart';
import 'package:attendanceapp/screens/admin_dashboards/qr_code_generator.dart';
import 'package:attendanceapp/screens/leave_calander.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/logout_screen.dart';
import 'admin_dashboards/employee_master.dart';
import 'admin_with_calendar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final List<Map<String, dynamic>> menuItems = const [
    {"icon": Icons.people, "label": "Employee Master", "content": "View Employee Details"},
    {"icon": Icons.date_range_sharp, "label": "Attendance", "content": "View attendance details"},
    {"icon": Icons.calendar_month_sharp, "label": "Calendar", "content": "Leave Calendar"},
    {"icon": Icons.request_page, "label": "Requests", "content": "Leave Requests"},
    {"icon": Icons.table_chart_outlined, "label": "Codes", "content": "View codes"},
    {"icon": Icons.qr_code_sharp, "label": "QR Code", "content": "Generate QR Code"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi Admin'),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF9D0B22)),
              accountName: Text('Admin'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Center(child: Icon(Icons.person, size: 40, color: Color(0xFF9D0B22))),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LogoutScreen()),
                );

              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF0F0F0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                final label = menuItems[index]['label'];
                if (label == 'Employee Master') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeMasterScreen()),
                  );
                } else if (label == 'Calendar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHomeWithCalendar()),
                  );
                }
                else if (label == 'Attendance') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
                  );
                }else if (label == 'Codes') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CodesMasterScreen()),
                  );
                }
                else if (label == 'QR Code') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRCodeGeneratorScreen(userEmail: 'admin@company.com')),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
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
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
