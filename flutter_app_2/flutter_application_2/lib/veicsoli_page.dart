import 'package:flutter/material.dart';
import 'package:flutter_application_2/veiculo_page.dart';

class VeicsoliPage extends StatelessWidget {
  final Map<String, dynamic> veiculo;

  const VeicsoliPage({super.key, required this.veiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Solicitar ${veiculo['nome']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modelo: ${veiculo['marca']}', style: TextStyle(fontSize: 18)),
            Text('ID: ${veiculo['id']}', style: TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () => _confirmarSolicitacao(context),
              child: const Text('Confirmar Solicitação'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarSolicitacao(BuildContext context) {
    // Implementar lógica de confirmação
    Navigator.pop(context);
  }
}
