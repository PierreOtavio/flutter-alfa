import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart'; // Verifique o caminho
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  List<Veiculo> veiculos = [];
  List<Veiculo> filtroAply = [];

  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token'; // <-- SUA CHAVE REAL

  final String apiUrl =
      kIsWeb
          ? 'http://127.0.0.1:8000/api/veiculos/disponiveis'
          : Platform.isAndroid
          ? 'http://10.0.2.2:8000/api/veiculos/disponiveis'
          : 'http://127.0.0.1:8000/api/veiculos/disponiveis';

  @override
  void initState() {
    super.initState();
    getVeiculos();
    searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilter);
    searchController.dispose();
    super.dispose();
  }

  void _handleError(dynamic e) {
    if (!mounted) return;
    print('Erro detalhado: $e');
    String message;
    if (e is SocketException || e is http.ClientException) {
      message = 'Erro de conexão. Verifique a rede ou a URL da API ($apiUrl).';
    } else if (e is FormatException) {
      message = 'Erro ao processar a resposta do servidor.';
    } else if (e is PlatformException &&
        (e.code == 'UnsupportedOSVersion' ||
            e.message?.contains('available') == true)) {
      message =
          'Erro: Armazenamento seguro não suportado nesta plataforma/versão.';
    } else if (e is PlatformException) {
      message = 'Erro no armazenamento seguro: ${e.message} (${e.code})';
    } else {
      message = e is Exception ? e.toString() : 'Ocorreu um erro inesperado.';
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
    }
    setState(() {
      isLoading = false;
      errorMessage = message;
    });
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        print(
          "Token lido do SharedPreferences (Web): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } catch (e) {
        print("Erro ao ler SharedPreferences na Web: $e");
        _handleError("Erro ao acessar preferências na web: $e");
        return null;
      }
    } else {
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        print(
          "Token lido do Secure Storage (Mobile): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } on PlatformException catch (e) {
        print("Erro ao ler token do Secure Storage: $e");
        _handleError(e);
        return null;
      } catch (e) {
        print("Erro inesperado ao ler Secure Storage: $e");
        _handleError("Erro inesperado ao ler armazenamento: $e");
        return null;
      }
    }
  }

  Future<void> getVeiculos() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? authToken;
    try {
      authToken = await _getToken();

      if (authToken == null || authToken.isEmpty) {
        print('Token não encontrado ou inválido. Redirecionando para login.');
        setState(() {
          isLoading = false;
          errorMessage =
              'Autenticação necessária. Faça o login para continuar.';
        });
        // await _logoutAndRedirect(showError: false);
        return;
      }

      final Map<String, String> headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('Buscando veículos em: $apiUrl');
      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is Map<String, dynamic> &&
            data.containsKey('veiculos') &&
            data['veiculos'] is List) {
          final List<dynamic> veiculosJson = data['veiculos'];
          // !!! Garanta que Veiculo.fromJson pega os IDs corretamente !!!
          final List<Veiculo> fetchedVeiculos =
              veiculosJson
                  .map((json) => Veiculo.fromJson(json as Map<String, dynamic>))
                  .toList();
          setState(() {
            veiculos = fetchedVeiculos;
            _applyFilter(); // Aplica filtro inicial/atual
            isLoading = false;
          });
        } else {
          print(
            "API retornou 200 OK, mas formato inesperado. Body: ${response.body}",
          );
          setState(() {
            veiculos = [];
            filtroAply = [];
            isLoading = false;
            errorMessage =
                data is Map && data.containsKey('message')
                    ? data['message']
                    : "Resposta inesperada do servidor.";
          });
        }
      } else if (response.statusCode == 401) {
        print('Erro 401: Token inválido/expirado. Deslogando...');
        setState(() {
          isLoading = false;
          errorMessage = 'Sessão expirada ou inválida. Faça o login novamente.';
        });
        // await _logoutAndRedirect(showError: false);
      } else if (response.statusCode == 404) {
        var data = jsonDecode(response.body);
        print("API retornou 404: ${data['error'] ?? response.body}");
        setState(() {
          errorMessage =
              data['error'] ?? 'Nenhum veículo disponível encontrado (404).';
          veiculos = [];
          filtroAply = [];
          isLoading = false;
        });
      } else {
        throw Exception(
          'Falha ao carregar veículos (Status: ${response.statusCode}) - Resposta: ${response.body}',
        );
      }
    } catch (e) {
      print("Erro no bloco principal de getVeiculos: $e");
      _handleError(e);
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Função _applyFilter (MODIFICADA PARA USAR IDs) ---
  void _applyFilter() {
    if (!mounted) return;
    final query = searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filtroAply = veiculos;
      } else {
        filtroAply =
            veiculos.where((veiculo) {
              final placaLower = veiculo.placa.toLowerCase();
              final chassiLower = veiculo.chassi.toLowerCase();

              // Converte os IDs (int?) para String para a busca por texto.
              // Se o ID for null, usa uma string vazia para não dar erro.
              final marcaIdStr = veiculo.marca?.toString() ?? '';
              final modeloIdStr = veiculo.modelo?.toString() ?? '';

              // Verifica se a query está contida em algum dos campos (incluindo IDs como string)
              return placaLower.contains(query) ||
                  chassiLower.contains(query) ||
                  marcaIdStr.contains(
                    query,
                  ) || // Busca no ID da marca (convertido para string)
                  modeloIdStr.contains(
                    query,
                  ); // Busca no ID do modelo (convertido para string)
            }).toList();
      }
    });
  }
  // --- Fim da Modificação ---

  void _scanQrCode() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRCodeScannerPage(), // Use o nome correto
      ),
    );
  }

  void _handleVeiculoSelect(Veiculo veiculo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VeicSoliPage(veiculo: veiculo)),
    );
    // Implemente a ação desejada
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Veículos'),

      //   /* ... AppBar igual ... */
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   centerTitle: true,
      //   title: const Text(
      //     'Lista de Veículos',
      //     style: TextStyle(fontSize: 25, color: Colors.white),
      //   ),

      //   backgroundColor: const Color(0xFF013A65),
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.vertical(bottom: Radius.circular(18.5)),
      //   ),
      //   toolbarHeight: 100,
      // ),
      backgroundColor: const Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              // Campo de pesquisa
              controller: searchController,
              decoration: InputDecoration(
                hintText:
                    "Pesquisar por Placa, Chassi, ID Marca/Modelo...", // Hint atualizado
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              // Título
              "Veículos disponíveis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              // Conteúdo
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? _buildErrorWidget(errorMessage!)
                      : filtroAply.isEmpty
                      ? _buildEmptyListWidget()
                      : _buildVeiculoList(), // <= Chamada modificada implicitamente
            ),
            Padding(
              // Botão QR Code
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _scanQrCode,
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  "Ler QR Code do Veículo",
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

  Widget _buildErrorWidget(String message) {
    // ... (Widget de erro igual ao anterior) ...
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent[100],
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.orangeAccent[100], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            if (message.contains("Autenticação necessária") ||
                message.contains("Sessão expirada"))
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Tentar Novamente"),
                onPressed: getVeiculos,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListWidget() {
    // ... (Widget de lista vazia igual ao anterior) ...
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          searchController.text.isEmpty
              ? "Nenhum veículo disponível encontrado."
              : "Nenhum veículo encontrado para '${searchController.text}'.",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- Widget _buildVeiculoList (MODIFICADO PARA MOSTRAR IDs) ---
  Widget _buildVeiculoList() {
    return ListView.builder(
      itemCount: filtroAply.length,
      itemBuilder: (context, index) {
        final veiculo = filtroAply[index];
        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8,
          ), // Espaço entre os containers
          padding: const EdgeInsets.all(16), // Preenchimento interno
          decoration: BoxDecoration(
            color: Colors.grey[800], // Fundo cinza escuro
            borderRadius: BorderRadius.circular(10), // Bordas arredondadas
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placa: ${veiculo.placa}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8), // Espaço entre os textos
                    Text(
                      'Marca: ${veiculo.marca.marca ?? "N/A"} | '
                      'Modelo: ${veiculo.modelo.modelo ?? "N/A"} | '
                      'Cor: ${veiculo.cor ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[400], height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VeicSoliPage(veiculo: veiculo),
                    ),
                  ); // Função ao clicar no botão
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
