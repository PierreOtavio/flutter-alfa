import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';

class SolicitacaoVeiculoPage extends StatelessWidget {
  final List<Map<String, String>> veiculos = [
    {'modelo': 'Honda Civic', 'placa': 'xxxx-1234'},
    {'modelo': 'Toyota Corolla', 'placa': 'yyyy-4567'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: const CustomAppBar(title: 'Veículos Solicitados'),
      // appBar: AppBar(
      //   backgroundColor: Colors.blue[900],
      //   title: const Text(
      //     'Veículo Solicitado',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       // Ação de voltar
      //     },
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: () {
      //         // Ação de atualizar
      //       },
      //     ),
      //   ],
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: veiculos.length,
          itemBuilder: (context, index) {
            final veiculo = veiculos[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Veículo: ${veiculo['modelo']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Placa: ${veiculo['placa']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      // Ação do botão "+"
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
