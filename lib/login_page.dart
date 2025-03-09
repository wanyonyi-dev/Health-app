import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _mobileNumber = '';
  bool _isCreatingAccount = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Doctor credentials
  final String _doctorEmail = 'doctor@gmail.com';
  final String _doctorPassword = '823Abt254@';

  // Theme colors
  final primaryColor = const Color(0xFF4F6CFF);
  final secondaryColor = const Color(0xFF2A2A72);
  final backgroundColor = const Color(0xFFF9FAFC);
  final cardColor = Colors.white;
  final errorColor = const Color(0xFFFF6B6B);
  final successColor = const Color(0xFF28A745);
  final textColor = const Color(0xFF2D3748);
  final subtitleColor = const Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      hintStyle: TextStyle(color: subtitleColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      errorStyle: TextStyle(color: errorColor),
    );
  }

  Future<void> _handleForgotPassword() async {
    String? resetEmail;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 20),
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
            child: Text('Cancel', style: TextStyle(color: subtitleColor)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_resetFormKey.currentState!.validate()) {
                _resetFormKey.currentState!.save();
                Navigator.pop(context, resetEmail);
              }
            },
            child: const Text('Reset Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        if (_isCreatingAccount) {
          await _handlePatientAuth();
          return;
        }

        // Check if attempting doctor login
        if (_email == _doctorEmail && _password == _doctorPassword) {
          try {
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: _email,
              password: _password,
            );

            // Check/create doctor document in Firestore
            DocumentSnapshot doctorDoc = await _firestore
                .collection('doctors')
                .doc(userCredential.user!.uid)
                .get();

            if (!doctorDoc.exists) {
              // Create doctor profile if first time login
              await _firestore.collection('doctors').doc(userCredential.user!.uid).set({
                'email': _email,
                'userType': 'doctor',
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
                'specialization': 'General Medicine',
                'name': 'Doctor',
                'lastLogin': FieldValue.serverTimestamp(),
              });
            } else {
              // Update last login time
              await _firestore.collection('doctors').doc(userCredential.user!.uid).update({
                'lastLogin': FieldValue.serverTimestamp(),
              });
            }

            if (!mounted) return;

            _showSuccessMessage('Welcome back, Doctor!');
            Navigator.of(context).pushReplacementNamed('/doctorDashboard');
            return;
          } catch (e) {
            _showErrorMessage('Error signing in as doctor. Please try again.');
            setState(() => _isLoading = false);
            return;
          }
        }

        // Handle regular patient login if not a doctor
        await _handlePatientLogin();

      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Invalid password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
          default:
            errorMessage = 'Authentication failed: ${e.message}';
        }
        _showErrorMessage(errorMessage);
      } catch (e) {
        _showErrorMessage('An unexpected error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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

    // Update last login time
    await _firestore.collection('patients').doc(userCredential.user!.uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    _showSuccessMessage('Login successful!');
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _handlePatientAuth() async {
    // Check if email already exists
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      await _firestore.collection('patients').doc(userCredential.user!.uid).set({
        'email': _email,
        'userType': 'patient',
        'mobileNumber': _mobileNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSuccessMessage('Account created successfully!');
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw e; // Let the outer catch block handle FirebaseAuthExceptions
      } else {
        throw Exception('Failed to create account: $e');
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.08,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
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

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.8),
            secondaryColor,
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildLoginForm(),
              const SizedBox(height: 32),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.medical_services_rounded,
            size: 54,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Health Hub',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCreatingAccount ? 'Create Patient Account' : 'Welcome Back',
          style: TextStyle(
            fontSize: 16,
            color: subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('Email Address'),
        const SizedBox(height: 8),
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
          onSaved: (value) => _email = value!,
        ),
        const SizedBox(height: 24),
        _buildFormLabel('Password'),
        const SizedBox(height: 8),
        TextFormField(
          decoration: _getInputDecoration(
            hint: 'Enter your password',
            icon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: primaryColor,
                size: 22,
              ),
              onPressed: _togglePasswordVisibility,
            ),
          ),
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your password';
            if (_isCreatingAccount && value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onChanged: (value) => _password = value,
        ),
        if (!_isCreatingAccount) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
        if (_isCreatingAccount) ..._buildRegistrationFields(),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  List<Widget> _buildRegistrationFields() {
    return [
      const SizedBox(height: 24),
      _buildFormLabel('Confirm Password'),
      const SizedBox(height: 8),
      TextFormField(
        decoration: _getInputDecoration(
          hint: 'Confirm your password',
          icon: Icons.lock_rounded,
        ),
        obscureText: !_isPasswordVisible,
        validator: (value) {
          if (value != _password) return 'Passwords do not match';
          return null;
        },
        onChanged: (value) => _confirmPassword = value,
      ),
      const SizedBox(height: 24),
      _buildFormLabel('Mobile Number'),
      const SizedBox(height: 8),
      TextFormField(
        decoration: _getInputDecoration(
          hint: 'Enter your mobile number',
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 54),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isCreatingAccount
                  ? 'Already have an account?'
                  : 'Don\'t have an account?',
              style: TextStyle(color: subtitleColor),
            ),
            TextButton(
              onPressed: _isLoading ? null : () {
                setState(() => _isCreatingAccount = !_isCreatingAccount);
              },
              child: Text(
                _isCreatingAccount ? 'Login' : 'Sign up',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}