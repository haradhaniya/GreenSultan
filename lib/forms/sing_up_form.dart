import 'package:flutter/material.dart';

class UserForm extends StatelessWidget {
  final TextEditingController userController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback toggleConfirmPasswordVisibility;

  const UserForm({
    super.key,
    required this.userController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.togglePasswordVisibility,
    required this.toggleConfirmPasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Username Field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: userController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.green, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.person, color: Colors.black54),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username cannot be empty';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters long';
              }
              return null;
            },
          ),
        ),
        // Email Field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.green, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.email, color: Colors.black54),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email cannot be empty';
              }
              String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
              RegExp regex = RegExp(pattern);
              if (!regex.hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
        // Password Field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.green, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.lock, color: Colors.black54),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password cannot be empty';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                return 'Password must contain at least one number';
              }
              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                return 'Password must contain at least one uppercase letter';
              }
              if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                return 'Password must contain at least one special character';
              }
              return null;
            },
          ),
        ),
        // Confirm Password Field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: confirmPasswordController,
            obscureText: !isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.green, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              suffixIcon: IconButton(
                icon: Icon(
                  isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: toggleConfirmPasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
