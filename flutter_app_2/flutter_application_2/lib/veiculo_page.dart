import 'dart:convert';
import "package:flutter/material.dart";
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/inicio_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/goals/globals.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/services.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});
  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> veiculos = [];
  List<Map<String, dynamic>> veiculosFiltrados = [];
  String resultadoQR = "";

  @override
  void initState() {
    super.initState();
    buscarVeiculo();
  }

  // Método para ler QR Code
  Future<void> lerQRCode() async {
    String barcodeScanRes;

    try {
      // Chamando o scanner com os parâmetros:
      // - "#FF013A65" (cor da linha de escaneamento - azul da sua interface)
      // - "Cancelar" (texto do botão de cancelar)
      // - true (mostrar botão de flash)
      // - ScanMode.QR (modo de escaneamento: apenas QR code)
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#FF013A65",
        "Cancelar",
        true,
        ScanMode.QR,
      );

      // Se o usuário cancelar, retorna "-1"
      if (barcodeScanRes != "-1") {
        setState(() {
          resultadoQR = barcodeScanRes;
        });

        // Aqui você pode implementar a lógica para buscar o veículo pelo QR Code
        buscarVeiculoPorQRCode(barcodeScanRes);
      }
    } on PlatformException {
      setState(() {
        resultadoQR = "Erro ao escanear QR code";
      });
    }
  }

  // Método para buscar veículo pelo QR Code
  Future<void> buscarVeiculoPorQRCode(String qrCode) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Você pode implementar a lógica específica para buscar na API pelo QR Code
      // Por exemplo:
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/veiculos/qrcode/$qrCode'),
      );

      if (response.statusCode == 200) {
        // Processa o resultado
        Map<String, dynamic> veiculo = jsonDecode(response.body);

        // Mostra um snackbar com o resultado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veículo encontrado: ${veiculo['nome']}')),
        );
      }
    } catch (e) {
      print("Erro ao buscar veículo por QR Code: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veículo não encontrado')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> buscarVeiculo() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/veiculos'),
      );

      if (response.statusCode == 200) {
        print('Resposta: ${response.body}');
        List<dynamic> vehicles = jsonDecode(response.body);

        List<Map<String, dynamic>> availableVehicles =
            vehicles
                .where((vehicle) => vehicle['status'] == 'disponivel')
                .map(
                  (vehicle) => {
                    'nome': vehicle['nome'] ?? 'Sem nome',
                    'marca': vehicle['marca'] ?? 'Sem marca',
                  },
                )
                .toList();

        setState(() {
          veiculos = availableVehicles;
          veiculosFiltrados = availableVehicles;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar veículos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filtrarVeiculos(String query) {
    setState(() {
      if (query.isEmpty) {
        veiculosFiltrados = veiculos;
      } else {
        veiculosFiltrados =
            veiculos
                .where(
                  (veiculo) => veiculo['nome'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFFFFFFFF)),
          iconSize: 30,
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Lista de Veículos',
          style: TextStyle(fontSize: 25, color: Color(0xFFFFFFFF)),
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            iconSize: 30,
            onPressed: () => buscarVeiculo(),
          ),
        ],
        backgroundColor: Color(0xFF013A65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.5)),
        ),
        toolbarHeight: 100,
      ),
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de pesquisa
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquise um carro",
                suffixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: filtrarVeiculos,
            ),
            SizedBox(height: 16),

            // Título da lista de veículos disponíveis
            Text(
              "Veículos disponíveis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // Lista de veículos ou indicador de carregamento
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: veiculosFiltrados.length,
                        itemBuilder: (context, index) {
                          final veiculo = veiculosFiltrados[index];
                          return Card(
                            color: Colors.grey[850],
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                veiculo['nome'],
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                veiculo['marca'],
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${veiculo['nome']} adicionado ao carrinho!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // Botão para leitura de QR Code
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: lerQRCode, // Conecta ao método de leitura de QR Code
              icon: Icon(Icons.camera_alt, color: Colors.white),
              label: Text(
                "Leia um QR Code",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF013A65),
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
