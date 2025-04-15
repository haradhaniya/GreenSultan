import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../forms/city_select_drop_down.dart';
import '../forms/role_select_drop_down.dart';
import '../forms/sing_up_form.dart';
import '../provider/city_provider.dart';
import '../provider/selected_city_provider.dart';
import '../provider/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _selectedRole = 'Owner'; // Default role is 'Owner'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityProvider2.notifier).fetchCities();
    });
  }

  Future<void> saveUserData(String email, String password, String selectedCity,
      String selectedRole) async {
    try {
      // Verify that selectedCity is a valid city name and not a role
      final cityList = ref.read(cityProvider2);
      if (!cityList.contains(selectedCity)) {
        showSnackbar(
            'Error: Invalid city selected. Please choose a valid city.');
        return;
      }

      // First create user in Firebase Authentication
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data in Firestore under the correct city document
      await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('Green_Sultan_Users')
          .doc(email)
          .set({
        'name': _userController.text.trim(),
        'email': email,
        'role': selectedRole,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update provider state
      await ref.read(userProvider.notifier).saveUser(
            _userController.text.trim(),
            email,
            selectedCity,
            selectedRole,
          );
    } catch (e) {
      showSnackbar('Error creating account: $e');
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Check access rights immediately before rendering
    final hasAccess = ref.read(hasPermissionProvider('AdminSection'));

    if (!hasAccess) {
      // If no access, redirect back or show an access denied screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You do not have permission to access this section')),
        );
      });
    }

    final size = MediaQuery.of(context).size;
    final cities = ref.watch(cityProvider2);
    final selectedCity = ref.watch(cityProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.green[400],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              buildCard(size, selectedCity, cities),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(Size size, String? selectedCity, List<String> cities) {
    return FadeInUp(
      duration: const Duration(
          milliseconds: 800), // Adjusted duration for a smoother effect
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildHeaderText(),
                const SizedBox(height: 25),
                logo(100),
                const SizedBox(height: 30),
                CityDropdown(
                  selectedCity: selectedCity,
                  cities: cities,
                  onCityChanged: (value) {
                    ref.read(cityProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 15),
                // Role selection dropdown
                RoleDropdown(
                  selectedRole: _selectedRole,
                  onRoleChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
                ),
                const SizedBox(height: 15),
                // Call the UserForm widget here
                UserForm(
                  userController: _userController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  isPasswordVisible: _isPasswordVisible,
                  isConfirmPasswordVisible: _isConfirmPasswordVisible,
                  togglePasswordVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  toggleConfirmPasswordVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 20),
                signUpButton(size, selectedCity),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeaderText() {
    return Column(
      children: [
        Text(
          'Create User Account',
          style: GoogleFonts.poppins(
            fontSize: 26.0,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          'Join us and start your journey',
          style: GoogleFonts.poppins(fontSize: 14.0, color: Color(0xFF6C6C6C)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget logo(double size) {
    return Image.asset(
      'images/app_logo.png',
      height: size,
      width: size,
      semanticLabel: 'Application Logo',
    );
  }

  Widget signUpButton(Size size, String? selectedCity) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState?.validate() ?? false) {
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();

          if (selectedCity != null && _selectedRole != null) {
            try {
              // Register the user with Firebase
              await saveUserData(email, password, selectedCity, _selectedRole!);

              // Show success message
              showSnackbar(
                  'User Creation successful! Welcome ${_userController.text}');
            } catch (e) {
              // Handle signup errors
              showSnackbar('User Creation failed: $e');
            }
          } else {
            showSnackbar('Please select a city and a role');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: Size(size.width, size.height / 17),
      ),
      child: Text(
        'Create Account',
        style: GoogleFonts.poppins(
          fontSize: 16.0,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
