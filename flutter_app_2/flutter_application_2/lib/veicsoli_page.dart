import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/veiculo.dart';

class VeicSoliPage extends StatelessWidget {
  final Veiculo veiculo;

  const VeicSoliPage({super.key, required this.veiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitação - ${veiculo.placa}'),
        backgroundColor: const Color(0xFF013A65),
      ),
      backgroundColor: const Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Veículo',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Placa: ${veiculo.placa}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Chassi: ${veiculo.chassi}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Ano: ${veiculo.ano}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Cor: ${veiculo.cor}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Capacidade: ${veiculo.capacidade} pessoas',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Observações: ${veiculo.obsVeiculo}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Adicione aqui a lógica para realizar a solicitação
                print('Solicitação realizada para o veículo ${veiculo.placa}');
              },
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Realizar Solicitação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF013A65),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
