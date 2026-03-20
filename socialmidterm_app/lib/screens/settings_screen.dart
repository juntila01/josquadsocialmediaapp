import 'package:flutter/material.dart';
import '../main.dart'; // Connection: Required to access the MyApp state for theme changes

class SettingsScreen extends StatefulWidget {

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // State: Local boolean to track the visual state of the toggle switch
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),

      body: ListTile(
        title: const Text("Dark Mode"),

        // UI: The toggle switch for theme selection
        trailing: Switch(
          value: darkMode,

          // Logic: When the user toggles the switch
          onChanged: (value) {
            setState(() {
              darkMode = value; // Logic: Updates the local switch UI
            });

            // Connection: Calls the 'toggleTheme' method defined in main.dart
            // This triggers a rebuild of the entire MaterialApp with the new theme
            MyApp.of(context)?.toggleTheme(value);
          },
        ),
      ),
    );
  }
}