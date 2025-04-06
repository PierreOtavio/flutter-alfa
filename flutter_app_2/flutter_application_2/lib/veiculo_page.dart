import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/veiculo_repository.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  final VeiculoRepository _repository = VeiculoRepository();
  List<Veiculo> veiculosFiltrados = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  Future<void> _carregarVeiculos() async {
    setState(() => isLoading = true);
    try {
      await _repository.carregarVeiculos();
      setState(() {
        veiculosFiltrados = _repository.veiculos;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar veículos: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  void _filtrarVeiculos(String query) {
    setState(() {
      if (query.isEmpty) {
        veiculosFiltrados = _repository.veiculos;
      } else {
        veiculosFiltrados = _repository.buscarLocalmente(query);
      }
    });
  }

  Future<void> _lerQRCode() async {
    try {
      final resultadoQR = await FlutterBarcodeScanner.scanBarcode(
        "#FF013A65",
        "Cancelar",
        true,
        ScanMode.QR,
      );

      if (resultadoQR != "-1") {
        Veiculo? veiculoEncontrado;

        try {
          veiculoEncontrado = _repository.veiculos.firstWhere(
            (veiculo) => veiculo.qrCode == resultadoQR,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veículo encontrado: ${veiculoEncontrado.placa}'),
            ),
          );
          // Aqui você poderia navegar para página de solicitação
          // Navigator.push(context, MaterialPageRoute(builder: (context) => VeicsoliPage(veiculo: veiculoEncontrado)));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'QR Code não corresponde a nenhum veículo disponível.',
              ),
            ),
          );
        }
      }
    } on PlatformException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao acessar a câmera')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao ler QR Code: $e')));
    }
  }

  void _navegarParaSolicitacao(Veiculo veiculo) {
    // Implemente a navegação para a página de solicitação
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VeicsoliPage(veiculo: veiculo.toJson()),
      ),
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
            onPressed: _carregarVeiculos,
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
              controller: _searchController,
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
              onChanged: _filtrarVeiculos,
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
                        itemCount: veiculosFiltrados.length,
                        itemBuilder: (context, index) {
                          final veiculo = veiculosFiltrados[index];
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
                                    () => _navegarParaSolicitacao(veiculo),
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
                onPressed: _lerQRCode,
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
