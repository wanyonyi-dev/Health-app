import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<String> _users = []; // List to manage users
  final _doctorNameController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _maxPatientsController = TextEditingController();
  final _registrationController = TextEditingController();

  void _addDoctor() {
    if (_doctorNameController.text.isEmpty) {
      _showSnackbar('Please enter a doctor name');
      return;
    }
    print("Doctor added: ${_doctorNameController.text}");
    _doctorNameController.clear();
    _showSnackbar('Doctor added successfully');
  }

  void _addService() {
    if (_serviceNameController.text.isEmpty || _maxPatientsController.text.isEmpty) {
      _showSnackbar('Please fill in all fields');
      return;
    }
    print("Service added: ${_serviceNameController.text} with max patients: ${_maxPatientsController.text}");
    _serviceNameController.clear();
    _maxPatientsController.clear();
    _showSnackbar('Service added successfully');
  }

  void _registerNewUser() {
    if (_registrationController.text.isEmpty) {
      _showSnackbar('Please enter an email or phone number');
      return;
    }
    setState(() {
      _users.add(_registrationController.text);
      _registrationController.clear();
    });
    _showSnackbar('User registered successfully');
  }

  void _deleteUser(String user) {
    setState(() {
      _users.remove(user);
    });
    _showSnackbar('User deleted successfully');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('Add Doctor'),
            _buildTextField(_doctorNameController, 'Doctor Name'),
            _buildElevatedButton('Add Doctor', _addDoctor),
            const Divider(),

            _buildSectionTitle('Add Service'),
            _buildTextField(_serviceNameController, 'Service Name'),
            _buildTextField(_maxPatientsController, 'Max Patients', isNumber: true),
            _buildElevatedButton('Add Service', _addService),
            const Divider(),

            _buildSectionTitle('Register New User'),
            _buildTextField(_registrationController, 'User Email/Phone'),
            _buildElevatedButton('Register User', _registerNewUser),
            const Divider(),

            _buildSectionTitle('Registered Users'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_users[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteUser(_users[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildElevatedButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
