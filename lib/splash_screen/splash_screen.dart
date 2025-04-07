import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../home.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error occurred')),
          ); // Handle error case
        } else {
          var user = snapshot.data;
          log("User: ${user?.uid}"); // Log user information for debugging

          // Return splash screen with logo and navigation after checking auth state
          Future.delayed(const Duration(seconds: 3), () {
            if (user == null) {
              // Navigate to LoginScreen if no user is logged in
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            } else {
              // Navigate to HomeScreen if the user is logged in
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Splash screen background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // App logo in the center
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'images/app_logo.png', // Replace with your app logo
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                // Circular progress indicator at the bottom
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
