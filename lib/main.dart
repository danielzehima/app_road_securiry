import 'package:flutter/material.dart';

import 'ui/driving_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoadSecurityApp());
}

class RoadSecurityApp extends StatelessWidget {
  const RoadSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sécurité Routière CI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFF77F00), // orange
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFF77F00),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const DrivingScreen(),
    );
  }
}
