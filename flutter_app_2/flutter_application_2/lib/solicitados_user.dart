import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/veiculo.dart';

class SolicitadosUser extends StatefulWidget {
  const SolicitadosUser({super.key});

  @override
  State<SolicitadosUser> createState() => _SolicitadosUserState();
}

class _SolicitadosUserState extends State<SolicitadosUser> {
  @override
  void initState() {
    super.initState();
    postSolic();
  }

  Future<void> postSolic() async {}

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
