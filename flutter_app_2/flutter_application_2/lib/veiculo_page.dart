import 'package:flutter/material.dart';
import 'package:flutter_application_2/main.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({Key? key}) : super(key: key);
  _VeiculoPageState createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  String ticket = '';

  readQRCode() async {
    try 
    {
      String code = await FlutterBarcodeScanner.scanBarcode(
      'FFFFFFF',
      'Cancelar',
      true,
      ScanMode.QR,
    );

    setState(() => ticket = code != '-1' ? code : 'Inválido');
    } catch(e)  {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (ticket != null) 
            {
              Padding(
                child: ,
              ),
            },
          ],
        ),
      ),
    );
  }
}
