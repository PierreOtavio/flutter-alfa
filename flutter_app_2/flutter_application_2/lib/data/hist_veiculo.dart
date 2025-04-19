class HistVeiculo {
  final int id;
  final int veiculoId;
  final int solicitacaoId;
  final int kmInicio;
  final int kmFinal;
  final int kmGasto;

  HistVeiculo({
    required this.id,
    required this.veiculoId,
    required this.solicitacaoId,
    required this.kmInicio,
    required this.kmFinal,
    required this.kmGasto,
  });

  factory HistVeiculo.fromJson(Map<String, dynamic> json) {
    return HistVeiculo(
      id: json['id'],
      veiculoId: json['veiculo_id'],
      solicitacaoId: json['solicitacao_id'],
      kmInicio: json['km_inicio'] ?? 0, // <-- Aqui pega o valor correto
      kmFinal: json['km_final'] ?? 0,
      kmGasto: json['km_gasto'] ?? 0,
    );
  }
}
