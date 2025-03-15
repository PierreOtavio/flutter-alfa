import 'package:flutter/material.dart';

class BlackTeste extends StatelessWidget {
  const BlackTeste({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('DEU CERTO O LOGIN'),
      ),
    );
  }
}
