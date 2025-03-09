import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/appointment_cart_provider.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'login_page.dart';
import 'daily_mood_logging_screen.dart';
import 'chat_screen.dart';
import 'appointment_booking_screen.dart';
import 'emergency_contacts_screen.dart' as emergency;
import 'calendar_screen.dart';
import 'legal_support_screen.dart';
import 'admin_dashboard.dart';
import 'doctor_dashboard.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppointmentCartProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppointmentCartProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Connect',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(userId: '',),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) {
          final auth = FirebaseAuth.instance;
          final userId = auth.currentUser?.uid ?? '';
          return HomeScreen(userId: userId);
        },
        '/moodLogging': (context) => const MoodLoggingScreen(),
        '/chat': (context) => ChatScreen(
          therapistName: ModalRoute.of(context)?.settings.arguments as String? ?? '',
        ),
        '/appointmentBooking': (context) => AppointmentBookingScreen(
          cartProvider: Provider.of<AppointmentCartProvider>(context),
        ),
        '/emergencyContacts': (context) => emergency.EmergencyContactsScreen(),
        '/calendar': (context) => CalendarScreen(
          cartProvider: Provider.of<AppointmentCartProvider>(context),
        ),
        '/legalSupport': (context) => const LegalSupportScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/doctorDashboard': (context) => DoctorDashboard(),
      },
    );
  }
}