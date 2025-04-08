// enum StatusVeiculo { disponivel, indisponivel, emManutencao }

class Veiculo {
  final int id;
  String placa;
  String chassi;
  String status;
  final String qrCode;
  String ano;
  String cor;
  int capacidade;
  String obsVeiculo; // Alterado para String
  int kmRevisao;

  Veiculo({
    required this.id,
    required this.placa,
    required this.chassi,
    required this.status,
    required this.qrCode,
    required this.ano,
    required this.cor,
    required this.capacidade,
    required this.obsVeiculo,
    required this.kmRevisao,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      id: json['id'],
      placa: json['placa'],
      chassi: json['chassi'],
      status: json['status_veiculo'],
      qrCode: json['qrCode'],
      ano: json['ano'],
      cor: json['cor'],
      capacidade: json['capacidade'],
      obsVeiculo: json['obs_veiculo'] ?? '',
      kmRevisao: json['km_revisao'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'chassi': chassi,
      'status': status.toString().split('.').last,
      'qrCode': qrCode,
      'ano': ano,
      'cor': cor,
      'capacidade': capacidade,
      'obsUser': obsVeiculo,
      'kmRevisao': kmRevisao,
    };
  }

  @override
  String toString() {
    return "Veiculo(id: $id, placa: $placa, chassi: $chassi, status: $status, qrCode: $qrCode, ano: $ano, cor: $cor, capacidade: $capacidade, obsUser: $obsVeiculo, kmRevisao: $kmRevisao)";
  }
}
