import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() => runApp(const DlpApp());

class DlpApp extends StatelessWidget {
  const DlpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Learning Passport',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
