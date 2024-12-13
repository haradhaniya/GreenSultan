import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/auth/login_screen.dart';
import 'package:green_sultan/home.dart';
import 'package:green_sultan/rider_app/main.dart';
import '../forms/city_select_drop_down.dart';
import '../forms/role_select_drop_down.dart';
import '../forms/sing_up_form.dart';
import '../fruits_veggies/products/veggies_price.dart';
import '../provider/city_provider.dart';
import '../provider/selected_city_provider.dart';
import '../provider/user_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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

  Future<void> saveUserData(String email, String password, String selectedCity, String selectedRole) async {
    try {
      // Save user data in Firestore
      await ref.read(userProvider.notifier).saveUser(
        _userController.text.trim(),
        email,
        selectedCity,
        selectedRole,
      );

      // Navigate based on the role
      navigateToRoleScreen(selectedRole);
    } catch (e) {
      showSnackbar('Error creating account: $e');
    }
  }

  // Role-based navigation
  void navigateToRoleScreen(String selectedRole) {
    Widget destinationScreen;

    // Use if-else to check the role and navigate accordingly
    if (selectedRole == 'owner') {
      destinationScreen = HomeScreen();
    } else if (selectedRole == 'administrator') {
      destinationScreen = VeggiesListBeforeVefification();
    } else if (selectedRole == 'rider') {
      destinationScreen = RiderApp();
    } else {
      destinationScreen = HomeScreen(); // Default screen if no role matched
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      duration:
      const Duration(milliseconds: 600), // Adjust the duration as needed
      child: Container(
        height: 800, // Increased height to accommodate dropdown
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
                footerText(context),
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
          'Create Account',
          style: GoogleFonts.inter(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          'Sign up to get started',
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

  Widget signUpButton(Size size, String? selectedCity) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();
          if (selectedCity != null && _selectedRole != null) {
            saveUserData(email, password, selectedCity, _selectedRole!);
          } else {
            showSnackbar('Please select a city and a role');
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: Size(size.width, size.height / 15),
      ),
      child: Text(
        'Sign up',
        style: GoogleFonts.inter(
          fontSize: 16.0,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget footerText(BuildContext context) {
    return Text.rich(
      TextSpan(
        style:
        GoogleFonts.inter(fontSize: 12.0, color: const Color(0xFF3B4C68)),
        children: [
          const TextSpan(text: 'Don’t have an account?'),
          TextSpan(
            text: ' Log in',
            style: const TextStyle(
                color: Color(0xFFFF5844), fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Navigate to the Sign Up screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
          ),
        ],
      ),
    );
  }
}
