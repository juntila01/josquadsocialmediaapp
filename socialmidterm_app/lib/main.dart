import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() {
  // Logic: Pre-bind the framework before initialization
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;

  // Connection: Initialize Firebase immediately.
  // We don't use 'late' to avoid initialization errors.
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

      // Logic: FutureBuilder handles the bridge between the Native Splash and the App
      home: FutureBuilder(
        future: _initialization,
        builder: (context, appSnapshot) {
          // UI: While Firebase connects, we return a blank Scaffold.
          // Because of 'flutter_native_splash', the user will continue to see
          // the logo from the native side until this is ready. No flicker!
          if (appSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: Colors.transparent);
          }

          if (appSnapshot.hasError) {
            return Scaffold(body: Center(child: Text("Firebase Error: ${appSnapshot.error}")));
          }

          // Connection: Once Firebase is ready, pass control to AuthWrapper
          return const AuthWrapper();
        },
      ),

      routes: {
        '/login': (context) => WelcomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // UI: Stay on a blank screen while checking the login session.
        // This keeps the native logo visible until the Home or Welcome screen is ready.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.transparent);
        }

        if (authSnapshot.hasData) {
          return HomeScreen(
            username: authSnapshot.data!.displayName ?? "User",
            profileImage: authSnapshot.data!.photoURL,
          );
        }

        return WelcomeScreen();
      },
    );
  }
}