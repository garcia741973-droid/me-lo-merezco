import 'package:flutter/material.dart';
import '../../core/services/order_service.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';

class QrPaymentScreen extends StatefulWidget {
  final int orderId;

  const QrPaymentScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  Map<String, dynamic>? paymentInfo;
  bool loading = true;

      Future<void> _downloadQr(String qrUrl) async {
        try {
          if (Platform.isAndroid) {
            final status = await Permission.photos.request();
            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso denegado')),
              );
              return;
            }
          }

          final response = await http.get(Uri.parse(qrUrl));

          if (response.statusCode != 200) {
            throw Exception('Error descargando imagen');
          }

          final directory = Directory('/storage/emulated/0/Download');

          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          final filePath =
              '${directory.path}/qr_pago_${DateTime.now().millisecondsSinceEpoch}.png';

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR guardado en Descargas ✅')),
          );

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }

      //sube el boton para cargar imagen de pago
            Future<String?> _pickAndUploadToCloudinary() async {
              final picker = ImagePicker();

              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );

              if (pickedFile == null) return null;

              final imageFile = File(pickedFile.path);

              return await CloudinaryService.uploadImage(imageFile);
            }      

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      final data =
          await OrderService.fetchPaymentInfo(widget.orderId);

      setState(() {
        paymentInfo = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (paymentInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Error cargando pago')),
      );
    }

    final total = paymentInfo!['order_total'];
    final amount = paymentInfo!['amount_to_pay'];
    final qrUrl = paymentInfo!['qr_image_url'];
    final validUntil = paymentInfo!['valid_until'];
    final stage = paymentInfo!['payment_stage'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago por QR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Escanea el QR para realizar el pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Image.network(
              qrUrl,
              height: 220,
              width: 220,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _downloadQr(qrUrl),
              icon: const Icon(Icons.download),
              label: const Text('Descargar QR'),
            ),

            const SizedBox(height: 24),

            Text('Total del pedido: Bs $total'),

            Text(
              stage == 'initial'
                  ? 'Primer pago'
                  : 'Pago final (saldo)',
            ),

            const SizedBox(height: 6),

            Text(
              'Monto a pagar: Bs ${amount.toString()}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'QR válido hasta: $validUntil',
              style: const TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
              onPressed: () async {
                try {
                  // payment_stage puede ser 'initial' o 'final' según lo que devolvió backend
                  final stage = paymentInfo!['payment_stage'] as String? ?? 'initial';

                  // 1️⃣ Elegir imagen y subir a Cloudinary
                  final imageUrl = await _pickAndUploadToCloudinary();

                  if (imageUrl == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se seleccionó imagen')),
                    );
                    return;
                  }

                  // 2️⃣ Enviar URL real al backend
                  await OrderService.uploadProof(
                    orderId: widget.orderId,
                    proofUrl: imageUrl,
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(stage == 'initial'
                          ? 'Comprobante anticipo enviado. Esperando verificación.'
                          : 'Comprobante pago final enviado. Esperando verificación.'),
                    ),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
                child: const Text('Subir comprobante / Ya pagué'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}