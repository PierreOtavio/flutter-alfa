import 'package:flutter/material.dart';

class CpfField extends StatelessWidget {
  final TextEditingController controller;

  const CpfField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: "CPF",
        prefixIcon: Icon(Icons.person, color: Color(0xFFC7C7CF)),
        labelStyle: TextStyle(color: Color(0xFFC7C7CF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Por favor, insira o seu CPF";
        }
        return null;
      },
    );
  }
}
