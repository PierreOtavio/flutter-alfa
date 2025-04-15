class Solicitar {
  final int veiculoId;
  String prevDataInicio;
  String prevHoraInicio;
  String prevDataFinal;
  String prevHoraFinal;
  String motivo;

  Solicitar({
    required this.veiculoId,
    required this.prevDataInicio,
    required this.prevHoraInicio,
    required this.prevDataFinal,
    required this.prevHoraFinal,
    required this.motivo,
  });

  factory Solicitar.fromJson(Map<String, dynamic> json) {
    return Solicitar(
      veiculoId: json['veiculo_id'],
      prevDataInicio: (json['prev_data_inicio']),
      prevHoraInicio: (json['prev_hora_inicio']),
      prevDataFinal: (json['prev_data_final']),
      prevHoraFinal: (json['prev_hora_final']),
      motivo: json['motivo'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'veiculo_id': veiculoId,
      'prev_data_inicio': prevDataInicio,
      'prev_hora_inicio': prevHoraInicio,
      'prev_data_final': prevDataFinal,
      'prev_hora_final': prevHoraFinal,
      'motivo': motivo,
    };
  }

  @override
  String toString() {
    return '(veiculo_id: $veiculoId, prev_data_inicio: $prevDataInicio, prev_hora_inicio: $prevHoraInicio, prev_data_final: $prevDataFinal, prev_hora_final: $prevHoraFinal, motivo: $motivo)';
  }
}
