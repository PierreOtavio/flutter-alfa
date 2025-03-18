import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class MyDropdownButton extends StatefulWidget {
  const MyDropdownButton({super.key});

  @override
  State<MyDropdownButton> createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {
  final List<String> items = ["adm", "user"];
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Ajuste de alinhamento
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          items:
              items
                  .map(
                    (String item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
          value: selectedValue,
          onChanged: (String? value) {
            setState(() {
              selectedValue = value;
            });
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12),
            height:
                50, // Ajustado para o mesmo tamanho dos campos de CPF e Senha
            width: double.infinity, // Mantém alinhado
          ),
          menuItemStyleData: const MenuItemStyleData(height: 40),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: Color(0xFFC7C7CF)),
            iconSize: 24,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFC7C7CF), width: 2), // Borda
            ),
          ),
          customButton: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 50, // Igual aos outros campos
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFC7C7CF), width: 2), // Borda
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFF303030),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: Color(0xFFC7C7CF),
                ), // Ícone engrenagem
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedValue ?? 'Selecione',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFC7C7CF),
                ), // Ícone seta
              ],
            ),
          ),
        ),
      ),
    );
  }
}
