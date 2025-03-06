import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching Google Calendar
import 'appointment_booking_screen.dart'; // Import the AppointmentBookingScreen
import './providers/appointment_cart_provider.dart';

class CalendarScreen extends StatefulWidget {
  final AppointmentCartProvider cartProvider;

  const CalendarScreen({super.key, required this.cartProvider});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Function to navigate to the appointment booking screen
  void _navigateToAppointmentBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingScreen(
          cartProvider: widget.cartProvider,  // Pass the cartProvider from parent widget
        ),
      ),
    );
  }

  // Function to open Google Calendar
  void _openGoogleCalendar() async {
    const url = 'https://calendar.google.com/';
    try {
      if (await canLaunch(url)) {
        await launch(url);
        // Navigate back to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open Google Calendar'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate back to home screen even if there's an error
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Calendar Activities'),
        centerTitle: true,
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // The image at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/doctor_image.png',
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Calendar widget with elevation and rounded corners
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      weekendDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Buttons with icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _navigateToAppointmentBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        minimumSize: const Size(double.infinity, 50), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      label: const Text('BOOK AN APPOINTMENT', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _openGoogleCalendar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 50), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_view_day, color: Colors.white),
                      label: const Text('OPEN GOOGLE CALENDAR', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}