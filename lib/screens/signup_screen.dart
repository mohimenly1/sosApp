import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers updated to match the new schema
  final _nameController = TextEditingController(); // Combined name
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedUserType;
  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate() || _selectedUserType == null) {
      if (_selectedUserType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a user type.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create user in Firebase Auth (handles email/password securely)
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // 2. Prepare user data for Firestore according to the new schema
        final userData = {
          'uid': newUser.uid, // The Primary Key
          'name': _nameController.text.trim(), // Full name
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          // DO NOT SAVE THE PASSWORD HERE
          'userType': _selectedUserType,
          'location': null, // Placeholder for location, can be updated later
          'medicalFileId': null, // Optional field, null by default
          'createdAt': Timestamp.now(),
        };

        // 3. Store the user data in 'users' collection in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set(userData);

        // 4. *** IMPORTANT: Navigate based on user role ***
        if (mounted) {
          _navigateUser(_selectedUserType!);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = e.message ?? 'An unknown error occurred.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper function to handle navigation
  void _navigateUser(String userType) {
    switch (userType) {
      case 'individual':
        Navigator.pushReplacementNamed(context, '/home'); // For regular users
        break;
      case 'rescue_team':
        Navigator.pushReplacementNamed(
            context, '/rescue_home'); // For rescue teams
        break;
      case 'government_entity':
        Navigator.pushReplacementNamed(context, '/gov_home'); // For government
        break;
      default:
        // Fallback to the generic home screen
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... (Image and Title are the same)
                  const SizedBox(height: 32),
                  Center(
                    child: Image.asset('lib/assets/Untitled.gif', height: 100),
                  ),
                  const SizedBox(height: 32),
                  const Text('Create Account',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2342)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // UPDATED: Single field for full name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your full name' : null,
                  ),
                  const SizedBox(height: 16),

                  // ... (Email and Phone fields are the same)
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return 'Enter an email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 16),

                  // ... (Password fields are the same)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Enter a password';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _isObscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isObscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _isObscureConfirm = !_isObscureConfirm),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // UPDATED: Added the third user type
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(labelText: 'User Type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'individual', child: Text('Individual')),
                      DropdownMenuItem(
                          value: 'rescue_team', child: Text('Rescue Team')),
                      DropdownMenuItem(
                          value: 'government_entity',
                          child: Text('Government Entity')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a user type' : null,
                  ),
                  const SizedBox(height: 32),

                  // ... (Button and Sign In link are the same)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2342),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Text('Sign up',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Sign in',
                            style: TextStyle(
                                color: Color(0xFF0A2342),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
