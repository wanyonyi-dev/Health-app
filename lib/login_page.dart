import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _resetFormKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _mobileNumber = '';
  bool _isDoctor = false;
  bool _isCreatingAccount = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final primaryColor = Color(0xFF6C63FF);
  final secondaryColor = Color(0xFF2A2A72);
  final backgroundColor = Color(0xFFF5F6F9);
  final cardColor = Colors.white;
  final errorColor = Color(0xFFFF6B6B);
  final successColor = Color(0xFF28A745);

  final String _doctorEmail = 'doctor@gmail.com';
  final String _doctorPassword = '823Abt254@';

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  InputDecoration _getInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: cardColor,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _handleForgotPassword() async {
    String? resetEmail;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Form(
          key: _resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: _getInputDecoration(
                  hint: 'Enter your email',
                  icon: Icons.email_rounded,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your email';
                  if (!EmailValidator.validate(value!)) return 'Please enter a valid email';
                  return null;
                },
                onSaved: (value) => resetEmail = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_resetFormKey.currentState!.validate()) {
                _resetFormKey.currentState!.save();
                Navigator.pop(context, resetEmail);
              }
            },
            child: Text('Reset Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).then((email) async {
      if (email != null) {
        setState(() => _isLoading = true);
        try {
          await _auth.sendPasswordResetEmail(email: email);
          _showSuccessMessage('Password reset email sent. Please check your inbox.');
        } catch (e) {
          _showErrorMessage('Failed to send reset email: ${e.toString()}');
        } finally {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Check if the user is a doctor
        if (_email == _doctorEmail && _password == _doctorPassword) {
          // Verify doctor exists in Firestore
          DocumentSnapshot doctorDoc = await _firestore
              .collection('doctors')
              .doc(userCredential.user!.uid)
              .get();

          if (doctorDoc.exists) {
            Navigator.of(context).pushReplacementNamed('/doctor_dashboard');
          } else {
            // Create doctor document if it doesn't exist
            await _firestore.collection('doctors').doc(userCredential.user!.uid).set({
              'email': _email,
              'userType': 'doctor',
              'createdAt': FieldValue.serverTimestamp(),
            });
            Navigator.of(context).pushReplacementNamed('/doctor_dashboard');
          }
        } else {
          // Handle patient login
          await _handlePatientLogin();
        }
      } catch (e) {
        _showErrorMessage(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePatientLogin() async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: _email,
      password: _password,
    );

    DocumentSnapshot userDoc = await _firestore
        .collection('patients')
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Patient account not found');
    }

    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _handlePatientAuth() async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _email,
      password: _password,
    );

    await _firestore.collection('patients').doc(userCredential.user!.uid).set({
      'email': _email,
      'userType': 'patient',
      'mobileNumber': _mobileNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.08,
                      vertical: 24,
                    ),
                    child: _buildLoginCard(),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 32),
              _buildLoginForm(),
              SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.medical_services,
          size: 64,
          color: primaryColor,
        ),
        SizedBox(height: 16),
        Text(
          'Health Hub',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _isCreatingAccount ? 'Create Patient Account' : 'Welcome Back',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          decoration: _getInputDecoration(
            hint: 'Email',
            icon: Icons.email_rounded,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your email';
            if (!EmailValidator.validate(value!)) return 'Please enter a valid email';
            return null;
          },
          onSaved: (value) => _email = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: _getInputDecoration(
            hint: 'Password',
            icon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: primaryColor,
              ),
              onPressed: _togglePasswordVisibility,
            ),
          ),
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your password';
            if (value!.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          onChanged: (value) => _password = value,
        ),
        if (!_isCreatingAccount) ...[
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (_isCreatingAccount) ..._buildRegistrationFields(),
      ],
    );
  }

  List<Widget> _buildRegistrationFields() {
    return [
      SizedBox(height: 16),
      TextFormField(
        decoration: _getInputDecoration(
          hint: 'Confirm Password',
          icon: Icons.lock_rounded,
        ),
        obscureText: !_isPasswordVisible,
        validator: (value) {
          if (value != _password) return 'Passwords do not match';
          return null;
        },
        onChanged: (value) => _confirmPassword = value,
      ),
      SizedBox(height: 16),
      TextFormField(
        decoration: _getInputDecoration(
          hint: 'Mobile Number',
          icon: Icons.phone_rounded,
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Please enter your mobile number';
          if (value!.length < 10) return 'Please enter a valid mobile number';
          return null;
        },
        onSaved: (value) => _mobileNumber = value!,
      ),
    ];
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: Text(
            _isCreatingAccount ? 'Create Account' : 'Login',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : () {
            setState(() => _isCreatingAccount = !_isCreatingAccount);
          },
          child: Text(
            _isCreatingAccount
                ? 'Already have an account? Login'
                : 'Don\'t have an account? Sign up',
            style: TextStyle(color: primaryColor),
          ),
        ),
      ],
    );
  }
}