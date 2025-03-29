import 'package:flutter/material.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({Key? key}) : super(key: key);
  _VeiculoPageState createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Veiculos')),
      body: Center(child: Text('Veiculos')),
    );
  }
}
