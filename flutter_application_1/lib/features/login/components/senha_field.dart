import 'package:flutter/material.dart';

class SenhaField extends StatefulWidget {
  final TextEditingController controller;

  const SenhaField({super.key, required this.controller});

  @override
  State<SenhaField> createState() => _SenhaFieldState();
}

class _SenhaFieldState extends State<SenhaField> {
  bool _passwordvisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_passwordvisible,
      decoration: InputDecoration(
        labelText: "Senha",
        suffixIcon: IconButton(
          icon: Icon(
            _passwordvisible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).primaryColorDark,
          ),
          onPressed: () {
            setState(() {
              _passwordvisible = !_passwordvisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Por favor, insira sua senha";
        }
        return null;
      },
    );
  }
}
