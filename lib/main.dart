import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';

void main() {
  runApp(const EveChatApp());
}

class EveChatApp extends StatelessWidget {
  const EveChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eve Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromRGBO(254, 113, 113, 1),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color.fromRGBO(254, 113, 113, 1),
          secondary: Color.fromRGBO(254, 113, 113, 1),
          surface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const ScanScreen(),
    );
  }
}
