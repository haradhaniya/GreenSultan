import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_sultan/splash_screen/splash_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope( // Initialize Riverpod here
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hara Dhaniya',
      theme: ThemeData(
        useMaterial3: false, // Use Material Design 3
        primarySwatch: Colors.green, // Primary color for the app
        scaffoldBackgroundColor: Colors.grey[50], // Light background color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.green[600], // Primary button color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            color: Colors.green[800],
            fontWeight: FontWeight.bold,
          ),
          labelLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.green[700], // Icon color
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          elevation: 4,
          color: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.green[700],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[300],
        ),
      ),
      home: SplashScreen(),
    );
  }
}

