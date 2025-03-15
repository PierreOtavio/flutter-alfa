import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class MyDropdwnButton extends StatefulWidget {
  const MyDropdwnButton({super.key});

  @override
  State createState() => _MyDropdwnButton();
}

class _MyDropdwnButton extends State {
  final items = ["adm", "user"];
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        hint: Text(
          'Select Item',
          style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
        ),
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
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          width: 140,
        ),
        menuItemStyleData: const MenuItemStyleData(height: 40),
      ),
    );
  }
}
