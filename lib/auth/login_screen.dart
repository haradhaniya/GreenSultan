import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/forms/login_form.dart';
import '../forms/city_select_drop_down.dart';
import '../home.dart';
import '../provider/city_provider.dart';
import '../provider/selected_city_provider.dart';
import '../provider/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final String? selectedRole = 'Owner'; // Default role is 'Owner'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityProvider2.notifier).fetchCities();
    });
  }

// Role-based navigation
  void navigateToRoleScreen(String selectedRole) {
    Widget destinationScreen;

    // Use if-else to check the role and navigate accordingly
    switch (selectedRole.toLowerCase()) {
      // Convert to lowercase for comparison
      case 'owner':
        destinationScreen = const HomeScreen();
        break;
      case 'administrator':
        destinationScreen =
            const HomeScreen(); // Changed to HomeScreen with access control
        break;
      case 'rider':
        // For riders, we now direct them to the HomeScreen which will handle access control
        destinationScreen = const HomeScreen();
        break;
      default:
        destinationScreen =
            const HomeScreen(); // Default screen if no role matched
    }

    // Navigate to the destination screen and remove previous screens from the navigation stack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String selectedCity = ref.read(cityProvider) ?? '';

    if (selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
      return;
    }

    try {
      // Sign in to Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if the user exists in Firestore for the selected city
      final userDoc = await FirebaseFirestore.instance
          .collection('Cities')
          .doc(selectedCity)
          .collection('Green_Sultan_Users')
          .doc(email)
          .get();

      if (!userDoc.exists) {
        // User doesn't exist in the selected city
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found for the selected city')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Save the user role to the provider
      final userRole = userDoc.data()?['role'] ?? 'user';

      // Save user data to provider
      await ref.read(userProvider.notifier).saveUserData(
            email,
            selectedCity,
            userRole, // Use the retrieved role
          );

      // Navigate based on the user's role
      navigateToRoleScreen(userRole);
    } on FirebaseAuthException catch (e) {
      // Handle auth exceptions
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else {
        message = e.message ?? 'An error occurred during authentication.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Handle other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cities = ref.watch(cityProvider2);
    final selectedCity = ref.watch(cityProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.green,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 70),
              buildCard(size, selectedCity, cities),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(Size size, String? selectedCity, List<String> cities) {
    return FadeInUp(
      duration: Duration(milliseconds: 600), // Adjust the duration as needed
      child: Container(
        height: 700,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildHeaderText(),
                const SizedBox(height: 25),
                logo(100),
                const SizedBox(height: 30),
                CityDropdown(
                  selectedCity: selectedCity,
                  cities: cities,
                  onCityChanged: (value) {
                    ref.read(cityProvider.notifier).setSelectedCity(value);
                  },
                ),
                const SizedBox(height: 10),
                LoginUserForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isPasswordVisible: _isPasswordVisible,
                  togglePasswordVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                signInButton(size, selectedCity),
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
          'Login Account',
          style: GoogleFonts.inter(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          'Discover your social & Try to Login',
          style:
              GoogleFonts.inter(fontSize: 14.0, color: const Color(0xFF969AA8)),
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

  Widget signInButton(Size size, String? selectedCity) {
    return ElevatedButton(
      onPressed: _authenticate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: Size(size.width, size.height / 15),
      ),
      child: Text(
        'Log in',
        style: GoogleFonts.inter(
          fontSize: 16.0,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
