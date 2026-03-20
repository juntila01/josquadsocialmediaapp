import 'package:flutter/material.dart';

// Logic: A reusable widget to maintain a consistent look for all input fields (Email, Password, Username)
class CustomTextField extends StatelessWidget {

  final String hint; // UI: The placeholder text shown inside the field
  final IconData icon; // UI: The icon displayed on the left side (prefix)
  final bool obscure; // Logic: Set to 'true' for passwords to hide the typing
  final TextEditingController controller; // Connection: Links the text typed by the user to your Auth logic

  const CustomTextField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false, // Logic: Defaults to false (visible text) unless specified
  });

  @override
  Widget build(BuildContext context) {

    return TextField(
      controller: controller,
      obscureText: obscure, // Logic: Toggles between dots (password) and plain text

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon), // UI: Displays the assigned icon (e.g., Icons.lock or Icons.email)

        // UI: Standardizes the spacing inside the text box for a professional look
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }
}