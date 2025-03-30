import 'package:flutter/material.dart';

class VeicsoliPage extends StatefulWidget {
  const VeicsoliPage({super.key});

  @override
  State<VeicsoliPage> createState() => _VeicsoliPageState();
}

class _VeicsoliPageState extends State<VeicsoliPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Veiculos Solicitados')));
  }
}
