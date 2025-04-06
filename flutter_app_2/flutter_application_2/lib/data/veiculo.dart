import 'package:flutter/widgets.dart';

class Veiculo {
  final int id;
  String placa;
  String chassi;
  Enum status;
  final String qrCode;
  String ano;
  String cor;
  int capacidade;
  Text obsUser;
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
    required this.obsUser,
    required this.kmRevisao,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      id: json['id'],
      placa: json['placa'],
      chassi: json['chassi'],
      status: json['status'],
      qrCode: json['qrCode'],
      ano: json['ano'],
      cor: json['cor'],
      capacidade: json['capacidade'],
      obsUser: json['obsUser'],
      kmRevisao: json['kmRevisao'],
    );
  }

  // Map<String, dynamic> toJson()
  // {
  //   return [
  //     'id' : id,
  //     'placa' : placa,
  //     'chassi': chassi,
  //     'status' : status,
  //     'qrCode': qrCode,
  //     'ano' : ano,
  //     'cor' : cor,
  //     'capacidade' : capacidade,
  //     'obsUser' : obsUser,
  //     'kmRevisao' : kmRevisao,
  //   ];
  // }

  @override
  String toString() {
    return "Veiculo(id : $id, placa: $placa, chassi: $chassi, status: $status, qrCode: $qrCode, ano: $ano, cor: $cor, capacidade: $capacidade, obsUser: $obsUser, kmRevisao: $kmRevisao)";
  }
}
