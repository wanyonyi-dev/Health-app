import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import './models/appointment.dart';
import './providers/appointment_cart_provider.dart';
import './utils/session_utils.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppointmentCartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Wrap the home widget with a Consumer to ensure provider is accessible
      home: Consumer<AppointmentCartProvider>(
        builder: (context, cartProvider, child) => AppointmentBookingScreen(
          cartProvider: cartProvider,
        ),
      ),
    );
  }
}

// Model classes
class Doctor {
  final String id;
  final String name;
  final String specialization;

  Doctor({required this.id, required this.name, required this.specialization});

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name'],
      specialization: map['specialization'],
    );
  }
}

class Service {
  final String id;
  final String name;
  final int maxSlotsPerSession;
  final List<String> doctorIds;

  Service({
    required this.id,
    required this.name,
    required this.maxSlotsPerSession,
    required this.doctorIds,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      maxSlotsPerSession: map['maxSlotsPerSession'],
      doctorIds: List<String>.from(map['doctorIds']),
    );
  }
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        authDomain: "YOUR_AUTH_DOMAIN",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        appId: "YOUR_APP_ID",
      ),
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    rethrow;
  }
}

class AppointmentBookingScreen extends StatefulWidget {
  final AppointmentCartProvider cartProvider;

  const AppointmentBookingScreen({
    super.key,
    required this.cartProvider,
  });

  @override
  _AppointmentBookingScreenState createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  String? _selectedService;
  String? _selectedDoctor;
  String? _selectedSession;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Sample services data - moved to a separate method
  List<Service> get services => _getServices();
  List<Service> _getServices() {
    return [
      Service(id: '1', name: 'General Consultation', maxSlotsPerSession: 15, doctorIds: ['1', '2']),
      Service(id: '2', name: 'Dental Services', maxSlotsPerSession: 8, doctorIds: ['3', '4']),
      Service(id: '3', name: 'Laboratory Tests', maxSlotsPerSession: 20, doctorIds: ['5', '6']),
      Service(id: '4', name: 'Pharmacy Services', maxSlotsPerSession: 25, doctorIds: ['7']),
      Service(id: '5', name: 'Maternity Services', maxSlotsPerSession: 10, doctorIds: ['8', '9']),
      Service(id: '6', name: 'Pediatric Care', maxSlotsPerSession: 12, doctorIds: ['10', '1']),
      Service(id: '7', name: 'Physiotherapy', maxSlotsPerSession: 6, doctorIds: ['2', '3']),
      Service(id: '8', name: 'Vaccination', maxSlotsPerSession: 30, doctorIds: ['4', '5']),
      Service(id: '9', name: 'X-Ray Services', maxSlotsPerSession: 15, doctorIds: ['6', '7']),
      Service(id: '10', name: 'Mental Health Services', maxSlotsPerSession: 8, doctorIds: ['8', '9']),
    ];
  }

  // Sample doctors data - moved to a separate method
  List<Doctor> get doctors => _getDoctors();
  List<Doctor> _getDoctors() {
    return [
      Doctor(id: '1', name: 'Dr. John Kama', specialization: 'General Practitioner'),
      Doctor(id: '2', name: 'Dr. Sarah Kanji', specialization: 'Pediatrician'),
      Doctor(id: '3', name: 'Dr. Michael Chien', specialization: 'Dentist'),
      Doctor(id: '4', name: 'Dr. Jane Munition', specialization: 'Gynecologist'),
      Doctor(id: '5', name: 'Dr. Peter proj', specialization: 'Laboratory Specialist'),
      Doctor(id: '6', name: 'Dr. Lucy Cambodia', specialization: 'Radiologist'),
      Doctor(id: '7', name: 'Dr. James Probiotic', specialization: 'Pharmacist'),
      Doctor(id: '8', name: 'Dr. Mary Neri', specialization: 'Obstetrician'),
      Doctor(id: '9', name: 'Dr. David monad', specialization: 'Psychiatrist'),
      Doctor(id: '10', name: 'Dr. Grace Iambus', specialization: 'Physiotherapist'),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _countyController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _showCart(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPatientInfoSection(),
                  const SizedBox(height: 20),
                  _buildServiceSelection(),
                  const SizedBox(height: 20),
                  if (_selectedService != null) _buildDoctorSelection(),
                  const SizedBox(height: 20),
                  if (_selectedDoctor != null) _buildDateTimeSelection(),
                  const SizedBox(height: 20),
                  _buildBookingButton(),
                ].animate(interval: const Duration(milliseconds: 100))
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .slideX(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value!);
                      if (age == null || age < 0 || age > 150) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your ID number';
                      }
                      if (value!.length < 5) {
                        return 'ID number must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countyController,
              decoration: const InputDecoration(
                labelText: 'County',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your county';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              value: _selectedService,
              items: services.map((Service service) {
                return DropdownMenuItem(
                  value: service.id,
                  child: Text(service.name),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedService = value;
                  _selectedDoctor = null;
                  _selectedSession = null;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a service';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSelection() {
    final Service selectedService = services.firstWhere((s) => s.id == _selectedService);
    final List<Doctor> availableDoctors = doctors
        .where((d) => selectedService.doctorIds.contains(d.id))
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Doctor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _selectedDoctor,
              items: availableDoctors.map((Doctor doctor) {
                return DropdownMenuItem(
                  value: doctor.id,
                  child: Text('${doctor.name} (${doctor.specialization})'),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedDoctor = value;
                  _selectedSession = null;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a doctor';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date and Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Calendar widget
            Card(
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                    _selectedSession = null; // Reset session when date changes
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Session selection - modified to work without index
            Column(
              children: [
                'Morning (8:00 AM - 1:00 PM)',
                'Afternoon (2:00 PM - 4:00 PM)',
              ].map((session) {
                bool isSessionAvailable = SessionUtils.isSessionAvailable(
                    session,
                    _selectedDate
                );

                // Default to max slots until we have the real data
                final Service service =
                services.firstWhere((s) => s.id == _selectedService);
                int availableSlots = service.maxSlotsPerSession;

                bool isAvailable = availableSlots > 0 && isSessionAvailable;
                String subtitle = isSessionAvailable
                    ? 'Available slots: $availableSlots'
                    : 'Session expired';

                return RadioListTile<String>(
                  title: Text(session),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  value: session,
                  groupValue: _selectedSession,
                  onChanged: isAvailable
                      ? (String? value) {
                    setState(() {
                      _selectedSession = value;
                    });
                  }
                      : null,
                  activeColor: Colors.blue,
                  tileColor: isAvailable ? null : Colors.grey.shade200,
                ).animate()
                    .fadeIn()
                    .scale();
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _selectedSession == null ? null : _bookAppointment,
      child: const Text(
        'Book Appointment',
        style: TextStyle(fontSize: 18),
      ),
    ).animate()
        .fadeIn()
        .scale();
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate session availability
    if (_selectedSession == null || !SessionUtils.isSessionAvailable(_selectedSession!, _selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected session has expired or is invalid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    setState(() => _isLoading = true);
  
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
  
      // Create the appointment document
      final appointment = {
        'patientId': user.uid,
        'patientName': _nameController.text,
        'phoneNumber': _phoneController.text,
        'age': int.parse(_ageController.text),
        'county': _countyController.text,
        'idNumber': _idNumberController.text,
        'serviceId': _selectedService,
        'doctorId': _selectedDoctor,
        'session': _selectedSession,
        'dateTime': Timestamp.fromDate(_selectedDate),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
  
      // First check if slot is still available
      final existingAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('serviceId', isEqualTo: _selectedService)
          .where('session', isEqualTo: _selectedSession)
          .where('dateTime', isEqualTo: Timestamp.fromDate(_selectedDate))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
  
      final service = services.firstWhere((s) => s.id == _selectedService);
      if (existingAppointments.docs.length >= service.maxSlotsPerSession) {
        throw Exception('Session is full. Please select another session.');
      }
  
      // Create the appointment
      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointment);
  
      // Add to user's appointments subcollection for easy access
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .add(appointment);
  
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
        ),
      );
  
      // Clear form
      _clearForm();
  
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Failed to book appointment';
      if (e is FirebaseException) {
        switch (e.code) {
          case 'permission-denied':
            errorMessage = 'You don\'t have permission to book appointments';
            break;
          case 'resource-exhausted':
            errorMessage = 'Session is full. Please select another session';
            break;
          default:
            errorMessage = e.message ?? 'Unknown error occurred';
        }
      } else {
        errorMessage = e.toString();
      }
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _ageController.clear();
    _countyController.clear();
    _idNumberController.clear();
    setState(() {
      _selectedService = null;
      _selectedDoctor = null;
      _selectedSession = null;
      _selectedDate = DateTime.now();
    });
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer<AppointmentCartProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Appointments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Appointment List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .orderBy('dateTime', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final appointments = snapshot.data?.docs ?? [];

                        if (appointments.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final doc = appointments[index];
                            final data = doc.data() as Map<String, dynamic>;
                            // Include the document ID when creating the appointment
                            final appointment = Appointment.fromMap(
                              data,
                              id: doc.id, // Pass the document ID here
                            );
                            return _buildAppointmentCard(context, appointment, provider);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    AppointmentCartProvider provider,
  ) {
    final service = services.firstWhere(
      (s) => s.id == appointment.serviceId,
      orElse: () => Service(
        id: '',
        name: 'Unknown Service',
        maxSlotsPerSession: 0,
        doctorIds: [],
      ),
    );
    
    final doctor = doctors.firstWhere(
      (d) => d.id == appointment.doctorId,
      orElse: () => Doctor(
        id: '',
        name: 'Unknown Doctor',
        specialization: '',
      ),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                service.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(doctor.name),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM dd, yyyy').format(appointment.dateTime)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(appointment.session),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: appointment.id != null 
                        ? () => _showRescheduleDialog(context, appointment)
                        : null,
                    icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                    label: const Text('Reschedule', style: TextStyle(color: Colors.blue)),
                  ),
                  Container(width: 1, height: 24, color: Colors.black12),
                  TextButton.icon(
                    onPressed: appointment.id != null 
                        ? () => _confirmDelete(context, appointment.id)
                        : null,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first appointment now',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, Appointment appointment) {
    DateTime selectedDate = DateTime.now();
    String? selectedSession;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Reschedule Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current appointment info
                            Card(
                              child: ListTile(
                                title: const Text('Current Appointment'),
                                subtitle: Text(
                                  'Date: ${DateFormat('MMM dd, yyyy').format(appointment.dateTime)}\n'
                                  'Session: ${appointment.session}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // New date selection
                            const Text(
                              'Select New Date:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 300,
                              child: CalendarDatePicker(
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                onDateChanged: (date) {
                                  setState(() => selectedDate = date);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Session selection
                            const Text(
                              'Select New Session:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('appointments')
                                  .where('dateTime', isEqualTo: Timestamp.fromDate(selectedDate))
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text('Error loading sessions');
                                }

                                final sessions = {
                                  'Morning (8:00 AM - 1:00 PM)': 0,
                                  'Afternoon (2:00 PM - 4:00 PM)': 0,
                                };

                                if (snapshot.hasData) {
                                  for (var doc in snapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    String session = data['session'] as String;
                                    sessions[session] = (sessions[session] ?? 0) + 1;
                                  }
                                }

                                return Column(
                                  children: sessions.entries.map((entry) {
                                    return RadioListTile<String>(
                                      title: Text(entry.key),
                                      value: entry.key,
                                      groupValue: selectedSession,
                                      onChanged: (value) {
                                        setState(() => selectedSession = value);
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: selectedSession == null ? null : () async {
                            if (appointment.id != null) {
                              await _rescheduleAppointment(
                                appointment.id,
                                selectedDate,
                                selectedSession!,
                              );
                              if (context.mounted) Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot reschedule: Invalid appointment ID'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _rescheduleAppointment(
    String? appointmentId,
    DateTime newDate,
    String newSession,
  ) async {
    if (appointmentId == null || appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid appointment ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'dateTime': Timestamp.fromDate(newDate),
            'session': newSession,
            'status': 'rescheduled',
            'updatedAt': FieldValue.serverTimestamp(),
            'lastRescheduled': FieldValue.serverTimestamp(),
            'rescheduledBy': FirebaseAuth.instance.currentUser?.uid,
          });
  
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rescheduled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rescheduling appointment: $errorMessage'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, String? appointmentId) async {
    if (appointmentId == null || appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid appointment ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  
    // We can safely use '!' here because we've checked for null above
    if (confirmed == true) {
      await _deleteAppointment(appointmentId);
    }
  }
  
  // Update the _deleteAppointment method signature to be explicit about non-null requirement
  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      setState(() => _isLoading = true);
      
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelledBy': FirebaseAuth.instance.currentUser?.uid,
          });
  
      await widget.cartProvider.removeAppointment(appointmentId);
  
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Helper method to get error messages
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'not-found':
          return 'Appointment not found';
        case 'permission-denied':
          return 'You don\'t have permission to cancel this appointment';
        default:
          return 'Error: ${error.message}';
      }
    }
    return 'Failed to cancel appointment';
  }

  void _setReminder(Appointment appointment) async {
    // Implement reminder functionality here
    // This could use local notifications or any other reminder system
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder set for your appointment'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

