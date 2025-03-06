import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';rt';
import './models/appointment.dart';
import './providers/appointment_cart_provider.dart'; {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
void main() async { _appointments = [];
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  runApp(pointment> get appointments => List.unmodifiable(_appointments);
    ChangeNotifierProvider(Loading;
      create: (_) => AppointmentCartProvider(),
      child: const MyApp(),
    ),nitialize stream subscription
  );id initializeAppointments(String userId) {
}   _listenToAppointments(userId);
  }
class MyApp extends StatelessWidget {
  const MyApp({super.key});s(String userId) {
    _firestore
  @overridellection('appointments')
  Widget build(BuildContext context) {erId)
    return MaterialApp(ime', descending: true)
      title: 'Health Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),    .map((doc) => Appointment.fromFirestore(doc.data()))
      // Wrap the home widget with a Consumer to ensure provider is accessible
      home: Consumer<AppointmentCartProvider>(
        builder: (context, cartProvider, child) => AppointmentBookingScreen(
          cartProvider: cartProvider,
        ),rror = error.toString();
      ),notifyListeners();
    );},
  } );
} }

// Model classesddAppointment(Appointment appointment) async {
class Doctor {
  final String id; true;
  final String name;s();
  final String specialization;
      await _firestore
  Doctor({required this.id, required this.name, required this.specialization});
          .doc(appointment.id)
  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],alse;
      name: map['name'],
      specialization: map['specialization'],
    );_isLoading = false;
  }   _error = e.toString();
}     notifyListeners();
      rethrow;
class Service {
  final String id;
  final String name;
  final int maxSlotsPerSession;t(String id) async {
  final List<String> doctorIds;
      _isLoading = true;
  Service({yListeners();
    required this.id,
    required this.name,collection('appointments').doc(id).delete();
    required this.maxSlotsPerSession,
    required this.doctorIds,
  }); notifyListeners();
    } catch (e) {
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(String();
      id: map['id'],s();
      name: map['name'],
      maxSlotsPerSession: map['maxSlotsPerSession'],
      doctorIds: List<String>.from(map['doctorIds']),
    );
  }uture<void> clearCart(String userId) async {
}   try {
      _isLoading = true;
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(tch();
      options: const FirebaseOptions(ore
        apiKey: "YOUR_API_KEY",ents')
        authDomain: "YOUR_AUTH_DOMAIN",serId)
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        appId: "YOUR_APP_ID",rence);
      ),
    );await batch.commit();
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    rethrow;Listeners();
  } } catch (e) {
}     _isLoading = false;
      _error = e.toString();
class AppointmentBookingScreen extends StatefulWidget {
  final AppointmentCartProvider cartProvider;
    }
  const AppointmentBookingScreen({
    super.key,
    required this.cartProvider,
  }); Appointment {
  final String id;
  @overrideing userId;
  _AppointmentBookingScreenState createState() => _AppointmentBookingScreenState();
} final String phoneNumber;
  final int age;
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
    required this.phoneNumber,
  // Sample services data - moved to a separate method
  List<Service> get services => _getServices();
  List<Service> _getServices() {
    return [ this.serviceId,
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
    ];patientName: data['patientName'],
  }   phoneNumber: data['phoneNumber'],
      age: data['age'],
  // Sample doctors data - moved to a separate method
  List<Doctor> get doctors => _getDoctors();
  List<Doctor> _getDoctors() {Id'],
    return [Id: data['doctorId'],
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
    ];'patientName': patientName,
  }   'phoneNumber': phoneNumber,
      'age': age,
  @overridety': county,
  void dispose() {idNumber,
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();romDate(dateTime),
    _countyController.dispose();
    _idNumberController.dispose();
    super.dispose();ieldValue.serverTimestamp(),
  } };
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(Screen extends StatelessWidget {
        title: const Text('Book Appointment'),
        actions: [rId;
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _showCart(context),
          ), this.cartProvider,
        ],ed this.userId,
      ),uper(key: key);
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(xt context) {
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,ppointment Cart'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPatientInfoSection(),weep),
                  const SizedBox(height: 20),art(context),
                  _buildServiceSelection(),
                  const SizedBox(height: 20),
                  if (_selectedService != null) _buildDoctorSelection(),
                  const SizedBox(height: 20),
                  if (_selectedDoctor != null) _buildDateTimeSelection(),
                  const SizedBox(height: 20),
                  _buildBookingButton(),
                ].animate(interval: const Duration(milliseconds: 100))
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .slideX(),er(
              ),  itemCount: cartProvider.appointments.length,
            ),    itemBuilder: (context, index) {
          ),        final appointment = cartProvider.appointments[index];
        ),          return AppointmentCard(
      ),              appointment: appointment,
    );                onDelete: () => _confirmDelete(context, appointment.id),
  }                 );
                  },
  Widget _buildPatientInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),ontext, String appointmentId) async {
        child: Column(await showDialog<bool>(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [xt) => AlertDialog(
            const Text(xt('Confirm Delete'),
              'Patient Information', sure you want to remove this appointment?'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),Button(
            const SizedBox(height: 16),pop(context, false),
            TextFormField(ext('Cancel'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',pop(context, true),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your name';
                } == true) {
                return null;oveAppointment(appointmentId);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(arCart(BuildContext context) async {
              controller: _phoneController,>(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),tments from cart?'),
              ), [
              keyboardType: TextInputType.phone,
              validator: (value) {ator.pop(context, false),
                if (value?.isEmpty ?? true) {
                  return 'Please enter your phone number';
                }ton(
                if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(d == true) {
              children: [clearCart(userId);
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',Widget {
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
                      return null;metric(horizontal: 16, vertical: 8),
                    },
                  ),appointment.patientName),
                ),Column(
                const SizedBox(width: 12),gnment.start,
                Expanded(
                  child: TextFormField(
                    controller: _idNumberController,(appointment.dateTime)}',
                    decoration: const InputDecoration(
                      labelText: 'ID Number',ion}'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),extStyle(
                    validator: (value) {ppointment.status),
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your ID number';
                      }
                      if (value!.length < 5) {
                        return 'ID number must be at least 5 characters';
                      }utton(
                      return null;elete_outline),
                    },nDelete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(ring status) {
              controller: _countyController,
              decoration: const InputDecoration(
                labelText: 'County',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),elled':
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your county';
                }
                return null;
              },            ),          ],        ),      ),    );  }  Widget _buildServiceSelection() {    return Card(      elevation: 4,      child: Padding(        padding: const EdgeInsets.all(16.0),        child: Column(          crossAxisAlignment: CrossAxisAlignment.start,          children: [            const Text(              'Select Service',              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),            ),            const SizedBox(height: 16),            DropdownButtonFormField<String>(              decoration: const InputDecoration(                border: OutlineInputBorder(),                prefixIcon: Icon(Icons.medical_services),              ),              value: _selectedService,              items: services.map((Service service) {                return DropdownMenuItem(                  value: service.id,                  child: Text(service.name),                );              }).toList(),              onChanged: (String? value) {                setState(() {                  _selectedService = value;                  _selectedDoctor = null;                  _selectedSession = null;                });              },              validator: (value) {                if (value == null) {                  return 'Please select a service';                }                return null;              },            ),          ],        ),      ),    );  }  Widget _buildDoctorSelection() {    final Service selectedService = services.firstWhere((s) => s.id == _selectedService);    final List<Doctor> availableDoctors = doctors        .where((d) => selectedService.doctorIds.contains(d.id))        .toList();    return Card(      elevation: 4,      child: Padding(        padding: const EdgeInsets.all(16.0),        child: Column(          crossAxisAlignment: CrossAxisAlignment.start,          children: [            const Text(              'Select Doctor',              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),            ),            const SizedBox(height: 16),            DropdownButtonFormField<String>(              decoration: const InputDecoration(                border: OutlineInputBorder(),                prefixIcon: Icon(Icons.person),              ),              value: _selectedDoctor,              items: availableDoctors.map((Doctor doctor) {                return DropdownMenuItem(                  value: doctor.id,                  child: Text('${doctor.name} (${doctor.specialization})'),                );              }).toList(),              onChanged: (String? value) {                setState(() {                  _selectedDoctor = value;                  _selectedSession = null;                });              },              validator: (value) {                if (value == null) {                  return 'Please select a doctor';                }                return null;              },            ),          ],        ),      ),    );  }  Widget _buildDateTimeSelection() {    return Card(      elevation: 4,      child: Padding(        padding: const EdgeInsets.all(16.0),        child: Column(          crossAxisAlignment: CrossAxisAlignment.start,          children: [            const Text(              'Select Date and Session',              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),            ),            const SizedBox(height: 16),            StreamBuilder<QuerySnapshot>(              stream: FirebaseFirestore.instance                  .collection('appointments')                  .where('serviceId', isEqualTo: _selectedService)                  .where('dateTime',                  isGreaterThanOrEqualTo: DateTime(                      _selectedDate.year, _selectedDate.month, _selectedDate.day))                  .where('dateTime',                  isLessThan: DateTime(                      _selectedDate.year, _selectedDate.month, _selectedDate.day + 1))                  .snapshots(),              builder: (context, snapshot) {                if (snapshot.hasError) {                  return Text('Error: ${snapshot.error}');                }                if (snapshot.connectionState == ConnectionState.waiting) {                  return const Center(child: CircularProgressIndicator());                }                final Map<String, int> sessionCounts = {                  'Morning (8:00 AM - 1:00 PM)': 0,                  'Afternoon (2:00 PM - 4:00 PM)': 0,                };                if (snapshot.hasData) {                  for (var doc in snapshot.data!.docs) {                    final data = doc.data() as Map<String, dynamic>;                    String session = data['session'] as String;                    sessionCounts[session] = (sessionCounts[session] ?? 0) + 1;                  }                }                final Service service =                services.firstWhere((s) => s.id == _selectedService);                return Column(                  children: sessionCounts.entries.map((entry) {                    int availableSlots =                        service.maxSlotsPerSession - entry.value;                    bool isAvailable = availableSlots > 0;                    return RadioListTile<String>(                      title: Text(entry.key),                      subtitle: Text(                        'Available slots: $availableSlots',                        style: TextStyle(                          color: isAvailable ? Colors.green : Colors.red,                        ),                      ),                      value: entry.key,                      groupValue: _selectedSession,                      onChanged: isAvailable                          ? (String? value) {                        setState(() {                          _selectedSession = value;                        });                      }                          : null,                      activeColor: Colors.blue,                      tileColor: isAvailable ? null : Colors.grey.shade200,                    ).animate()                        .fadeIn()                        .scale();                  }).toList(),                );              },            ),          ],        ),      ),    );  }  Widget _buildBookingButton() {    return ElevatedButton(      style: ElevatedButton.styleFrom(        padding: const EdgeInsets.symmetric(vertical: 15),        backgroundColor: Colors.blue,        shape: RoundedRectangleBorder(          borderRadius: BorderRadius.circular(10),        ),      ),      onPressed: _selectedSession == null ? null : _bookAppointment,      child: const Text(        'Book Appointment',        style: TextStyle(fontSize: 18),      ),    ).animate()        .fadeIn()        .scale();  }  Future<void> _bookAppointment() async {    if (!_formKey.currentState!.validate()) return;    try {      final String appointmentId = DateTime.now().millisecondsSinceEpoch.toString();            // Create appointment object      final appointment = Appointment(        id: appointmentId,        patientName: _nameController.text,        phoneNumber: _phoneController.text,        age: int.parse(_ageController.text),        county: _countyController.text,        idNumber: _idNumberController.text,        serviceId: _selectedService!,        doctorId: _selectedDoctor!,        dateTime: _selectedDate,        session: _selectedSession!,      );      // Add to cart provider      await widget.cartProvider.addAppointment(appointment);      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        const SnackBar(          content: Text('Appointment booked successfully'),          backgroundColor: Colors.green,        ),      );      _clearForm();    } catch (e) {      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(          content: Text('Error booking appointment: $e'),          backgroundColor: Colors.red,        ),      );    }  }  void _clearForm() {    _nameController.clear();    _phoneController.clear();    _ageController.clear();    _countyController.clear();    _idNumberController.clear();    setState(() {      _selectedService = null;      _selectedDoctor = null;      _selectedSession = null;      _selectedDate = DateTime.now();    });  }  void _showCart(BuildContext context) {    showModalBottomSheet(      context: context,      isScrollControlled: true,      backgroundColor: Colors.transparent,      builder: (context) {        return Container(          height: MediaQuery.of(context).size.height * 0.85,          decoration: const BoxDecoration(            color: Colors.white,            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),          ),          child: Consumer<AppointmentCartProvider>(            builder: (context, provider, child) {              if (provider.isLoading) {                return const Center(child: CircularProgressIndicator());              }              return Column(                children: [                  // Handle bar                  Container(                    margin: const EdgeInsets.only(top: 12),                    height: 4,                    width: 40,                    decoration: BoxDecoration(                      color: Colors.grey[300],                      borderRadius: BorderRadius.circular(2),                    ),                  ),                  // Header                  Padding(                    padding: const EdgeInsets.all(16),                    child: Row(                      mainAxisAlignment: MainAxisAlignment.spaceBetween,                      children: [                        const Text(                          'Your Appointments',                          style: TextStyle(                            fontSize: 24,                            fontWeight: FontWeight.bold,                            color: Color(0xFF1E293B),                          ),                        ),                        IconButton(                          icon: const Icon(Icons.close),                          onPressed: () => Navigator.pop(context),                        ),                      ],                    ),                  ),                  // Appointment List                  Expanded(                    child: StreamBuilder<QuerySnapshot>(                      stream: FirebaseFirestore.instance                          .collection('appointments')                          .orderBy('dateTime', descending: true)                          .snapshots(),                      builder: (context, snapshot) {                        if (snapshot.hasError) {                          return _buildErrorState(snapshot.error.toString());                        }                        if (snapshot.connectionState == ConnectionState.waiting) {                          return const Center(child: CircularProgressIndicator());                        }                        final appointments = snapshot.data?.docs ?? [];                        if (appointments.isEmpty) {                          return _buildEmptyState();                        }                        return ListView.builder(                          padding: const EdgeInsets.symmetric(horizontal: 16),                          itemCount: appointments.length,                          itemBuilder: (context, index) {                            final data = appointments[index].data() as Map<String, dynamic>;                            final appointment = Appointment.fromMap(data);                            return _buildAppointmentCard(context, appointment, provider);                          },                        );                      },                    ),                  ),                ],              );            },          ),        );      },    );  }  Widget _buildAppointmentCard(    BuildContext context,    Appointment appointment,    AppointmentCartProvider provider,  ) {    final service = services.firstWhere((s) => s.id == appointment.serviceId);    final doctor = doctors.firstWhere((d) => d.id == appointment.doctorId);    return Card(      elevation: 2,      margin: const EdgeInsets.only(bottom: 16),      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),      child: Container(        decoration: BoxDecoration(          borderRadius: BorderRadius.circular(16),          gradient: LinearGradient(            colors: [Colors.blue.shade50, Colors.white],            begin: Alignment.topLeft,            end: Alignment.bottomRight,          ),        ),        child: Column(          children: [            ListTile(              contentPadding: const EdgeInsets.all(16),              title: Text(                service.name,                style: const TextStyle(                  fontSize: 18,                  fontWeight: FontWeight.bold,                  color: Color(0xFF1E293B),                ),              ),              subtitle: Column(                crossAxisAlignment: CrossAxisAlignment.start,                children: [                  const SizedBox(height: 8),                  Row(                    children: [                      const Icon(Icons.person, size: 16, color: Colors.blue),                      const SizedBox(width: 8),                      Text(doctor.name),                    ],                  ),                  const SizedBox(height: 4),                  Row(                    children: [                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),                      const SizedBox(width: 8),                      Text(DateFormat('MMM dd, yyyy').format(appointment.dateTime)),                    ],                  ),                  const SizedBox(height: 4),                  Row(                    children: [                      const Icon(Icons.access_time, size: 16, color: Colors.blue),                      const SizedBox(width: 8),                      Text(appointment.session),                    ],                  ),                ],              ),            ),            Container(              decoration: const BoxDecoration(                border: Border(top: BorderSide(color: Colors.black12)),              ),              child: Row(                mainAxisAlignment: MainAxisAlignment.spaceEvenly,                children: [                  TextButton.icon(                    onPressed: () => _showRescheduleDialog(context, appointment),                    icon: const Icon(Icons.edit_calendar, color: Colors.blue),                    label: const Text('Reschedule', style: TextStyle(color: Colors.blue)),                  ),                  Container(                    width: 1,                    height: 24,                    color: Colors.black12,                  ),                  TextButton.icon(                    onPressed: () => _confirmDelete(context, appointment.id),                    icon: const Icon(Icons.delete_outline, color: Colors.red),                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),                  ),                ],              ),            ),          ],        ),      ),    );  }  Widget _buildEmptyState() {    return Center(      child: Column(        mainAxisAlignment: MainAxisAlignment.center,        children: [          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),          const SizedBox(height: 16),          Text(            'No appointments yet',            style: TextStyle(              fontSize: 18,              fontWeight: FontWeight.bold,              color: Colors.grey[600],            ),          ),          const SizedBox(height: 8),          Text(            'Book your first appointment now',            style: TextStyle(color: Colors.grey[500]),          ),        ],      ),    );  }  void _showRescheduleDialog(BuildContext context, Appointment appointment) {    DateTime selectedDate = DateTime.now();    String? selectedSession;    showDialog(      context: context,      builder: (context) => Dialog(        child: ConstrainedBox(          constraints: BoxConstraints(            maxHeight: MediaQuery.of(context).size.height * 0.8,            maxWidth: MediaQuery.of(context).size.width * 0.9,          ),          child: StatefulBuilder(            builder: (BuildContext context, StateSetter setState) {              return Padding(                padding: const EdgeInsets.all(16.0),                child: Column(                  mainAxisSize: MainAxisSize.min,                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [                    // Header                    const Text(                      'Reschedule Appointment',                      style: TextStyle(                        fontSize: 20,                        fontWeight: FontWeight.bold,                      ),                    ),                    const SizedBox(height: 16),                                        // Scrollable content                    Flexible(                      child: SingleChildScrollView(                        child: Column(                          mainAxisSize: MainAxisSize.min,                          crossAxisAlignment: CrossAxisAlignment.start,                          children: [                            // Current appointment info                            Card(                              child: ListTile(                                title: const Text('Current Appointment'),                                subtitle: Text(                                  'Date: ${DateFormat('MMM dd, yyyy').format(appointment.dateTime)}\n'                                  'Session: ${appointment.session}',                                ),                              ),                            ),                            const SizedBox(height: 16),                                                        // New date selection                            const Text(                              'Select New Date:',                              style: TextStyle(fontWeight: FontWeight.bold),                            ),                            SizedBox(                              height: 300,                              child: CalendarDatePicker(                                initialDate: DateTime.now(),                                firstDate: DateTime.now(),                                lastDate: DateTime.now().add(const Duration(days: 90)),                                onDateChanged: (date) {                                  setState(() => selectedDate = date);                                },                              ),                            ),                            const SizedBox(height: 16),                                                        // Session selection                            const Text(                              'Select New Session:',                              style: TextStyle(fontWeight: FontWeight.bold),                            ),                            const SizedBox(height: 8),                            StreamBuilder<QuerySnapshot>(                              stream: FirebaseFirestore.instance                                  .collection('appointments')                                  .where('dateTime', isEqualTo: Timestamp.fromDate(selectedDate))                                  .snapshots(),                              builder: (context, snapshot) {                                if (snapshot.hasError) {                                  return const Text('Error loading sessions');                                }                                final sessions = {                                  'Morning (8:00 AM - 1:00 PM)': 0,                                  'Afternoon (2:00 PM - 4:00 PM)': 0,                                };                                if (snapshot.hasData) {                                  for (var doc in snapshot.data!.docs) {                                    final data = doc.data() as Map<String, dynamic>;                                    String session = data['session'] as String;                                    sessions[session] = (sessions[session] ?? 0) + 1;                                  }                                }                                return Column(                                  children: sessions.entries.map((entry) {                                    return RadioListTile<String>(                                      title: Text(entry.key),                                      value: entry.key,                                      groupValue: selectedSession,                                      onChanged: (value) {                                        setState(() => selectedSession = value);                                      },                                    );                                  }).toList(),                                );                              },                            ),                          ],                        ),                      ),                    ),                                        // Action buttons                    const SizedBox(height: 16),                    Row(                      mainAxisAlignment: MainAxisAlignment.end,                      children: [                        TextButton(                          onPressed: () => Navigator.pop(context),                          child: const Text('Cancel'),                        ),                        const SizedBox(width: 8),                        ElevatedButton(                          onPressed: selectedSession == null ? null : () async {                            await _rescheduleAppointment(                              appointment.id,                              selectedDate,                              selectedSession!,                            );                            if (context.mounted) Navigator.pop(context);                          },                          child: const Text('Confirm'),                        ),                      ],                    ),                  ],                ),              );            },          ),        ),      ),    );  }  Future<void> _rescheduleAppointment(    String appointmentId,    DateTime newDate,    String newSession,  ) async {    try {      await FirebaseFirestore.instance          .collection('appointments')          .doc(appointmentId)          .update({        'dateTime': Timestamp.fromDate(newDate),        'session': newSession,        'lastUpdated': Timestamp.fromDate(DateTime.now()),      });      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        const SnackBar(          content: Text('Appointment rescheduled successfully'),          backgroundColor: Colors.green,        ),      );    } catch (e) {      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(          content: Text('Error rescheduling appointment: $e'),          backgroundColor: Colors.red,        ),      );    }  }  Future<void> _confirmDelete(BuildContext context, String appointmentId) async {    final confirmed = await showDialog<bool>(      context: context,      builder: (context) => AlertDialog(        title: const Text('Cancel Appointment'),        content: const Text('Are you sure you want to cancel this appointment?'),        actions: [          TextButton(            onPressed: () => Navigator.pop(context, false),            child: const Text('No'),          ),          TextButton(            onPressed: () => Navigator.pop(context, true),            child: const Text('Yes'),            style: TextButton.styleFrom(foregroundColor: Colors.red),          ),        ],      ),    );    if (confirmed == true) {      await _deleteAppointment(appointmentId);    }  }  void _setReminder(Appointment appointment) async {    // Implement reminder functionality here    // This could use local notifications or any other reminder system    if (!mounted) return;    ScaffoldMessenger.of(context).showSnackBar(      const SnackBar(        content: Text('Reminder set for your appointment'),        behavior: SnackBarBehavior.floating,      ),    );  }  Future<void> _deleteAppointment(String appointmentId) async {    try {      // Delete from Firestore      await FirebaseFirestore.instance          .collection('appointments')          .doc(appointmentId)          .delete();      // Delete from cart provider      await widget.cartProvider.removeAppointment(appointmentId);      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        const SnackBar(          content: Text('Appointment cancelled successfully'),          backgroundColor: Colors.green,          behavior: SnackBarBehavior.floating,        ),      );      // Close the bottom sheet after successful deletion      if (context.mounted) {        Navigator.pop(context);      }    } catch (e) {      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(          content: Text('Error cancelling appointment: $e'),          backgroundColor: Colors.red,          behavior: SnackBarBehavior.floating,        ),      );    }  }  Widget _buildErrorState(String error) {    return Center(      child: Column(        mainAxisAlignment: MainAxisAlignment.center,        children: [          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),          const SizedBox(height: 16),          Text(            'Oops! Something went wrong',            style: TextStyle(              fontSize: 18,              fontWeight: FontWeight.bold,              color: Colors.grey[600],            ),          ),          const SizedBox(height: 8),          Text(            error,            style: TextStyle(              color: Colors.grey[500],              fontSize: 14,            ),            textAlign: TextAlign.center,          ),          const SizedBox(height: 16),          ElevatedButton.icon(            onPressed: () => Navigator.pop(context),            icon: const Icon(Icons.refresh),            label: const Text('Try Again'),            style: ElevatedButton.styleFrom(              backgroundColor: Colors.blue,              foregroundColor: Colors.white,              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),              shape: RoundedRectangleBorder(                borderRadius: BorderRadius.circular(8),              ),
            ),
          ),
        ],
      ),
    );
  }
}

