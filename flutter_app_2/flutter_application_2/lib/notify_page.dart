import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';

class NotifyPage extends StatelessWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const CustomAppBar(title: 'Notificação'));
  }
}
