import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_page.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CX Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4F46E5),
        ),
      ),
      home: const SplashPage(),
    );
  }
}