import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Hub'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue, // Changed to match the previous design
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      }),
                    ],
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset('assets/images/logo.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Light blue background color
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16, // Adjusted spacing
          mainAxisSpacing: 16,
          children: [
            _buildTileButton(
              context,
              'Daily Mood Logging',
              Icons.sentiment_satisfied,
              '/moodLogging',
            ),
            _buildTileButton(
              context,
              'Guided Meditation',
              Icons.self_improvement,
              '/guidedMeditation',
            ),
            _buildTileButton(
              context,
              'Access Therapists',
              Icons.video_call,
              '/accessTherapists',
            ),
            _buildTileButton(
              context,
              'Appointment Booking',
              Icons.calendar_today,
              '/appointmentBooking',
            ),
            _buildTileButton(
              context,
              'Emergency Contacts',
              Icons.warning,
              '/emergencyContacts',
            ),
            _buildTileButton(
              context,
              'Locate Hospital',
              Icons.local_hospital,
              '/locateHospital',
            ),
            // New button for the Calendar module
            _buildTileButton(
              context,
              'Calendar',
              Icons.calendar_month,
              '/calendar', // Ensure the route is defined in main.dart
            ),
            // New button for the Legal Support Screen
            _buildTileButton(
              context,
              'Legal Support',
              Icons.gavel,
              '/legalSupport', // Ensure the route is defined in main.dart
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            textStyle: const TextStyle(fontSize: 18),
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Sign Out'),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
    );
  }

  Widget _buildTileButton(
      BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.purple), // Larger icons
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
