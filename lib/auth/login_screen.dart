import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/auth/signup_screen.dart';
import 'package:green_sultan/forms/login_form.dart';
import '../forms/city_select_drop_down.dart';
import '../forms/role_select_drop_down.dart';
import '../provider/city_provider.dart';
import '../provider/selected_city_provider.dart';
import '../provider/user_provider.dart';

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
  String? _selectedRole = 'Owner'; // Default role is 'Owner'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityProvider2.notifier).fetchCities();
    });
  }

  Future<void> saveUserData(String email, String selectedCity) async {
    try {
      await ref.read(userProvider.notifier).saveUserData(email, selectedCity);
      showSnackbar('User data saved successfully!');
    } catch (e) {
      showSnackbar('Error saving user data: $e');
    }
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
      duration: Duration(milliseconds: 600), // Adjust the duration as needed
      child: Container(
        height: 700,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
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
                RoleDropdown(
                  selectedRole: _selectedRole,
                  onRoleChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
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
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          final email = _emailController.text.trim();
          if (selectedCity != null) {
            saveUserData(email, selectedCity);
          } else {
            showSnackbar('Please select a city');
          }
        }
      },
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

  Widget footerText(BuildContext context) {
    return Text.rich(
      TextSpan(
        style:
            GoogleFonts.inter(fontSize: 12.0, color: const Color(0xFF3B4C68)),
        children: [
          const TextSpan(text: 'Don’t have an account?'),
          TextSpan(
            text: ' Sign up',
            style: const TextStyle(
                color: Color(0xFFFF5844), fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Navigate to the Sign Up screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
          ),
        ],
      ),
    );
  }
}
