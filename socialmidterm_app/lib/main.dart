import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart'; // Connected to: The main dashboard after login
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Logic: Handles user session persistence
import 'firebase_options.dart';

void main() async {
  // Logic: Ensures Flutter framework is ready before starting Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Connection: Connects the app to your specific Firebase project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // Logic: Allows child widgets to find this state to trigger theme changes
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // State: Default theme starts as Light
  ThemeMode themeMode = ThemeMode.light;

  // Logic: Function called by the toggle button in HomeScreen AppBar
  void toggleTheme(bool dark) {
    setState(() {
      themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Logic: The "Gatekeeper" of the app.
      // It listens to FirebaseAuth to see if a user is already logged in.
      home: StreamBuilder<User?>(
        // Connection: authStateChanges emits a new value whenever a user logs in or out
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Logic: Prevents a "flicker" of the login screen while checking local storage
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Logic: If user data exists in snapshot, the user is authenticated.
          // Connection: Passes basic Firebase Auth data (display name/photo) to HomeScreen.
          if (snapshot.hasData) {
            return HomeScreen(
              username: snapshot.data!.displayName ?? "User",
              profileImage: snapshot.data!.photoURL,
            );
          }

          // Logic: If snapshot is null, user is logged out or session expired.
          return WelcomeScreen();
        },
      ),

      // Connection: Named routes for navigating specifically to the login flow
      routes: {
        '/login': (context) => WelcomeScreen(),
      },
    );
  }
}