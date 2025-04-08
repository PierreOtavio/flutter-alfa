import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/goals/globals.dart';
import 'package:flutter_application_2/inicio_page.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart';
import 'package:path/path.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  List<Veiculo> veiculos = [];
  List<Veiculo> filtroAply = [];

  void initState() {
    super.initState();
    bringVehic();
  }

  Future<void> bringVehic() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/veiculos/disponiveis'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vehicData = data['veiculos'];
        print('reposta: ${vehicData}');

        instanceVeiculo = Veiculo(
          id: vehicData['id'],
          placa: vehicData['placa'],
          chassi: vehicData['chassi'],
          status: vehicData['status_veiculo'],
          qrCode: vehicData['qr_code'],
          ano: vehicData['ano'],
          cor: vehicData['cor'],
          capacidade: vehicData['capacidade'],
          obsVeiculo: vehicData['obs_veiculo'],
          kmRevisao: vehicData['km_revisao'],
        );

        print(instanceVeiculo);
      } else {
        return print('erro na API: ${response}');
      }
    } catch (e) {
      print('errors: ${e}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filtroVehic() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filtroAply =
          veiculos.where((veiculo) {
            return veiculo.placa.toLowerCase().contains(query) ||
                veiculo.chassi.toLowerCase().contains(query) ||
                veiculo.cor.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> scanQrCode(context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerPage()),
    );
  }

  void _navegarParaSolicitacao(Veiculo veiculo, context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VeicSoliPage(veiculo: veiculo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Lista de Veículos',
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: bringVehic,
          ),
        ],
        backgroundColor: const Color(0xFF013A65),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.5)),
        ),
        toolbarHeight: 100,
      ),
      backgroundColor: const Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de pesquisa
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Pesquise um carro",
                suffixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => _filtroVehic(),
            ),
            const SizedBox(height: 16),

            // Título da lista de veículos disponíveis
            const Text(
              "Veículos disponíveis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Lista de veículos ou indicador de carregamento
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: veiculos.length,
                        itemBuilder: (context, index) {
                          final veiculo = filtroAply[index];
                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                veiculo.placa,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                veiculo.chassi,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add, color: Colors.blue),
                                onPressed:
                                    () => _navegarParaSolicitacao(
                                      veiculo,
                                      context,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // Botão QR Code
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => scanQrCode(context),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  "Leia um QR Code",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013A65),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
