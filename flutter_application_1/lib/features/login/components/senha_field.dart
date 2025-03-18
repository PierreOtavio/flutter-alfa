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
        prefixIcon: Icon(Icons.lock, color: Color(0xFFC5C8D1)),
        labelText: "Senha",
        labelStyle: TextStyle(color: Color(0xFFC5C8D1)),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordvisible ? Icons.visibility : Icons.visibility_off,
            color: Color(0xFFC5C8D1),
          ),
          onPressed: () {
            setState(() {
              _passwordvisible = !_passwordvisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
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
