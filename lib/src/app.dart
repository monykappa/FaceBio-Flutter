import 'package:flutter/material.dart';
import 'package:facebio_flutter/src/screens/home_screen.dart';

class FaceBioApp extends StatelessWidget {
  const FaceBioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceBio',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}
