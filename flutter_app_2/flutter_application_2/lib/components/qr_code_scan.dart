import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  String? qrCodeResult; // Variável para armazenar o resultado do QR Code
  final MobileScannerController controller =
      MobileScannerController(); // Controlador da câmera

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        backgroundColor: const Color(0xFF013A65),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(), // Liga/desliga o flash
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed:
                () =>
                    controller
                        .switchCamera(), // Alterna entre câmera frontal e traseira
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    qrCodeResult =
                        barcodes.first.rawValue; // Captura o valor do QR Code
                  });
                  print('QR Code escaneado: $qrCodeResult');
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrCodeResult ?? 'Escaneie um QR Code',
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose(); // Libera os recursos da câmera ao sair da página
    super.dispose();
  }
}
