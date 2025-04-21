class Notificacao {
  final String id;
  final String tipo;
  final String mensagem;
  final Map<String, dynamic> detalhes;
  final Map<String, dynamic> rawJson;

  Notificacao({
    required this.id,
    required this.tipo,
    required this.mensagem,
    required this.detalhes,
    required this.rawJson,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'].toString(),
      tipo: json['data']['tipo']?.toString() ?? 'Sem tipo',
      mensagem: json['data']['mensagem']?.toString() ?? 'Sem mensagem',
      detalhes:
          (json['data']['detalhes'] as Map?)?.cast<String, dynamic>() ?? {},
      rawJson: json,
    );
  }

  String get nomeSolicitante {
    if (detalhes['user'] != null && detalhes['user']['name'] != null) {
      return detalhes['user']['name'];
    }
    final match = RegExp(r'de (.*?)(?=\s|$)').firstMatch(mensagem);
    return match?.group(1) ?? 'Usuário desconhecido';
  }

  String get placaVeiculo {
    if (detalhes['veiculo'] is Map && detalhes['veiculo']['placa'] != null) {
      return detalhes['veiculo']['placa'];
    } else if (detalhes['veiculo'] is String) {
      return detalhes['veiculo'];
    } else if (detalhes['modelo'] is Map &&
        detalhes['modelo']['placa'] != null) {
      return detalhes['modelo']['placa'];
    }
    return 'Placa não informada';
  }
}
