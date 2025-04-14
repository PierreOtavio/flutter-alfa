import 'package:flutter/foundation.dart';
import 'package:flutter_application_2/data/marca.dart';
import 'package:flutter_application_2/data/modelo.dart'; // Para debugPrint

class Veiculo {
  final int id; // Obrigatório
  final String placa; // Obrigatório
  final String chassi; // Obrigatório
  final String statusVeiculo; // Obrigatório (status_veiculo)
  final String qrCode; // Obrigatório (qr_code)
  final String ano; // Obrigatório (convertido de int)
  final String cor; // Obrigatório
  final int capacidade; // Obrigatório
  final String? obsVeiculo; // Opcional (pode ser null)
  final int kmRevisao; // Obrigatório
  final Modelo modelo; // Obrigatório
  final Marca marca; // Obrigatório

  Veiculo({
    required this.id,
    required this.placa,
    required this.chassi,
    required this.statusVeiculo,
    required this.qrCode,
    required this.ano,
    required this.cor,
    required this.capacidade,
    this.obsVeiculo, // Não é required
    required this.kmRevisao,
    required this.modelo,
    required this.marca,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    // Helper para verificar e obter valor obrigatório ou lançar erro
    T getRequiredField<T>(Map<String, dynamic> jsonMap, String key) {
      final value = jsonMap[key];
      if (value == null) {
        throw FormatException(
          "Campo obrigatório '$key' está faltando ou é nulo no JSON.",
          jsonMap,
        );
      }
      // Tenta fazer o cast. Se falhar, lança erro.
      try {
        return value as T;
      } catch (e) {
        throw FormatException(
          "Erro ao fazer cast do campo '$key' para o tipo '$T'. Valor recebido: '$value'.",
          jsonMap,
        );
      }
    }

    // Helper para converter ano (int) para String, tratando null
    String getAnoAsString(Map<String, dynamic> jsonMap, String key) {
      final value = jsonMap[key];
      if (value == null) {
        throw FormatException(
          "Campo obrigatório '$key' (ano) está faltando ou é nulo no JSON.",
          jsonMap,
        );
      }
      if (value is int) {
        return value.toString();
      }
      if (value is String) {
        // Se a API mudar e enviar string, aceita
        return value;
      }
      // Se for outro tipo, lança erro
      throw FormatException(
        "Campo '$key' (ano) não é um inteiro ou string. Valor recebido: '$value'.",
        jsonMap,
      );
    }

    try {
      return Veiculo(
        // Usa o helper para garantir que os campos obrigatórios existem e têm o tipo certo
        id: getRequiredField<int>(json, 'id'),
        placa: getRequiredField<String>(json, 'placa'),
        chassi: getRequiredField<String>(json, 'chassi'),
        statusVeiculo: getRequiredField<String>(
          json,
          'status_veiculo',
        ), // Chave correta
        qrCode: getRequiredField<String>(json, 'qr_code'), // Chave correta
        ano: getAnoAsString(json, 'ano'), // Conversão int -> String obrigatória
        cor: getRequiredField<String>(json, 'cor'),
        capacidade: getRequiredField<int>(json, 'capacidade'),

        // obsVeiculo é opcional, então tratamos null diretamente
        obsVeiculo: json['obs_veiculo'] as String?, // Cast seguro para String?
        // kmRevisao é obrigatório, mas se API *puder* mandar null, fornecemos default
        // Se for ABSOLUTAMENTE obrigatório na API, use getRequiredField
        kmRevisao:
            (json['km_revisao'] as int?) ??
            0, // Assume 0 se API mandar null, mas campo é obrigatório na classe
        // Alternativa estrita para kmRevisao (se API NUNCA deve mandar null):
        // kmRevisao: getRequiredField<int>(json, 'km_revisao'),
        modelo: Modelo.fromJson(json['modelo']),
        marca: Marca.fromJson(json['marca']), // Chave correta
      );
    } catch (e) {
      // Adiciona mais contexto ao erro antes de relançar ou tratar
      debugPrint(
        "Erro ao processar Veiculo.fromJson: $e\nJSON recebido: $json",
      );
      // Você pode querer relançar a exceção para ser pega no bloco try/catch de getVeiculos
      // ou retornar um objeto inválido/nulo dependendo da sua estratégia de erro.
      // Relançar é geralmente melhor para indicar falha na desserialização.
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    // Usa as chaves corretas que a API espera ao enviar dados
    return {
      'id': id,
      'placa': placa,
      'chassi': chassi,
      'status_veiculo': statusVeiculo, // Chave correta para API
      'qr_code': qrCode, // Chave correta para API
      // A API espera 'ano' como int ou string? Se for int, converte de volta.
      'ano':
          int.tryParse(ano) ??
          ano, // Tenta converter para int, senão mantém string
      'cor': cor,
      'capacidade': capacidade,
      'obs_veiculo':
          obsVeiculo, // Chave correta para API (envia null se for null)
      'km_revisao': kmRevisao, // Chave correta para API
      'modelo': modelo, // Chave correta para API
      'marca': marca, // Chave correta para API
    };
  }

  @override
  String toString() {
    // toString não precisa de chaves de API
    return "Veiculo(id: $id, placa: $placa, chassi: $chassi, status: $statusVeiculo, qrCode: $qrCode, ano: $ano, cor: $cor, capacidade: $capacidade, obsVeiculo: $obsVeiculo, kmRevisao: $kmRevisao, modeloId: $modelo, marcaId: $marca)";
  }
}
