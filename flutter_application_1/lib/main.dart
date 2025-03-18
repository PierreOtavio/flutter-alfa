import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/screens/login.dart';

void main() {
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter TESTE',
      theme: ThemeData(primaryColor: Color(0xFF303030)),
      home: const Login(),
    );
  }
}
