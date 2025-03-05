import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LegalSupportScreen extends StatefulWidget {
  const LegalSupportScreen({super.key});

  @override
  _LegalSupportScreenState createState() => _LegalSupportScreenState();
}

class _LegalSupportScreenState extends State<LegalSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _caseTypeController = TextEditingController();
  final _dateController = TextEditingController();
  final _involvedController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _hospitalController.dispose();
    _caseTypeController.dispose();
    _dateController.dispose();
    _involvedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Your Case'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.indigoAccent],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/justice_image.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInputField(
                  "Hospital Name / Branch / Town",
                  "Enter Hospital Name",
                  _hospitalController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the hospital name';
                    }
                    return null;
                  },
                ),
                _buildInputField(
                  "Type of Case",
                  "Charges, Abuse, Sexual, or Mistreat",
                  _caseTypeController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the type of case';
                    }
                    return null;
                  },
                ),
                _buildInputField(
                  "Date of Incident",
                  "DD / MM / YYYY",
                  _dateController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the date of incident';
                    }
                    try {
                      DateFormat('dd/MM/yyyy').parseStrict(value);
                    } catch (e) {
                      return 'Please enter a valid date in DD/MM/YYYY format';
                    }
                    return null;
                  },
                ),
                _buildInputField(
                  "Who was involved in the case?",
                  "Patient / Doctor / Manager / Security",
                  _involvedController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please specify who was involved';
                    }
                    return null;
                  },
                ),
                _buildInputField(
                  "Brief Description",
                  "Describe the case briefly",
                  _descriptionController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a brief description';
                    }
                    if (value.length < 10) {
                      return 'Description should be at least 10 characters long';
                    }
                    return null;
                  },
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Case Submitted Successfully'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        // Here you would typically send the data to a server or save it locally
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'SUBMIT CASE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      String hint,
      TextEditingController controller,
      String? Function(String?) validator, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: const TextStyle(color: Colors.yellow),
            ),
            style: const TextStyle(color: Colors.white),
            validator: validator,
          ),
        ],
      ),
    );
  }
}