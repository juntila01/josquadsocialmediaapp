import 'package:flutter/material.dart';
import 'package:socialmidterm_app/screens/login_screen.dart'; // Connection: Destination for the Login button
import 'package:socialmidterm_app/screens/signup_screen.dart'; // Connection: Destination for the Signup button

class WelcomeScreen extends StatelessWidget {

  // UI: Local color constants used to define the "JoshquadSocial" branding on this screen
  final Color primaryColor = Colors.blue;
  final Color secondaryColor = Colors.grey;

  // UI: Reusable style for the prominent "Signup" button
  ButtonStyle mainButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // UI: Reusable style for the cleaner, text-only "Login" button
  ButtonStyle textButton() {
    return TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Logic: Provides the first visual interface a user sees if they are not logged in (via main.dart StreamBuilder)
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              // UI: Main branding logo (Replaced generic camera icon with your asset)
              // Logic: Ensure 'assets/logo.png' is in your pubspec.yaml
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                // UI: Safety fallback to the camera icon if the image fails to load
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.camera_alt,
                  size: 90,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 20),

              // UI: The official name of your social application
              const Text(
                "JoshquadSocial",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // SIGNUP BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  style: mainButton(),

                  // Connection: Navigates the user to the account creation flow
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignUpScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    "Signup",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // LOGIN BUTTON
              TextButton(
                style: textButton(),

                // Connection: Navigates the user to the existing account login flow
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(),
                    ),
                  );
                },

                child: const Text("Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}