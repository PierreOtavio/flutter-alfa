import 'dart:convert';
import 'package:http/http.dart' as http;
import 'veiculo.dart';

class VeiculoRepository {
  static final VeiculoRepository _instance = VeiculoRepository._internal();
  List<Veiculo> _veiculos = [];

  factory VeiculoRepository() => _instance;

  VeiculoRepository._internal();

  List<Veiculo> get veiculos => _veiculos;

  Future<void> carregarVeiculos() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/veiculos'),
      );

      if (response.statusCode == 200) {
        List<dynamic> dados = jsonDecode(response.body);
        _veiculos = dados.map((json) => Veiculo.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Erro ao carregar veículos: $e');
    }
  }

  List<Veiculo> buscarLocalmente(String query) {
    return _veiculos
        .where(
          (veiculo) =>
              veiculo.placa.toLowerCase().contains(query.toLowerCase()) ||
              veiculo.chassi.toLowerCase().contains(query.toLowerCase()) ||
              veiculo.cor.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
