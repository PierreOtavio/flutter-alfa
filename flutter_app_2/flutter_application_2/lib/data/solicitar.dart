class Solicitar {
  int id;
  int veiculoId;
  DateTime prevDataInicio;
  DateTime prevHoraInicio;
  DateTime prevDataFinal;
  DateTime prevHoraFinal;

  Solicitar({
    required this.id,
    required this.veiculoId,
    required this.prevDataInicio,
    required this.prevHoraInicio,
    required this.prevDataFinal,
    required this.prevHoraFinal,
  });

  factory Solicitar.fromJson(Map<String, dynamic> json) {
    return Solicitar(
      id: json['id'],
      veiculoId: json['veiculo_id'],
      prevDataInicio: DateTime.parse(json['prev_data_inicio']),
      prevHoraInicio: DateTime.parse(json['prev_hora_inicio']),
      prevDataFinal: DateTime.parse(json['prev_data_final']),
      prevHoraFinal: DateTime.parse(json['prev_hora_final']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'veiculo_id': veiculoId,
      'prev_data_inicio': prevDataInicio,
      'prev_hora_inicio': prevHoraInicio,
      ' prev_data_final': prevDataFinal,
      'prev_hora_final': prevHoraFinal,
    };
  }

  @override
  String toString() {
    return '(id: $id, veiculo_id: $veiculoId, prev_data_inicio: $prevDataInicio, prev_hora_inicio: $prevHoraInicio, prev_data_final: $prevDataFinal, prev_hora_final: $prevHoraFinal)';
  }
}
