import 'package:flutter/material.dart';
import '../../core/services/order_service.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';

class AdminQrManagementScreen extends StatefulWidget {
  const AdminQrManagementScreen({super.key});

  @override
  State<AdminQrManagementScreen> createState() =>
      _AdminQrManagementScreenState();
}

class _AdminQrManagementScreenState
    extends State<AdminQrManagementScreen> {

  List<dynamic> _qrs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQrs();
  }

  Future<void> _loadQrs() async {
    try {
      final data = await OrderService.fetchAdminQrs();
      setState(() {
        _qrs = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _activate(int id) async {
    await OrderService.activateQr(id);
    await _loadQrs();
  }

Future<void> _showCreateQrDialog() async {
  final percentController = TextEditingController();
  DateTime? validFrom;
  DateTime? validUntil;
  File? selectedImage;
  String? uploadedUrl;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Crear nuevo QR'),
            content: SingleChildScrollView(
              child: Column(
                children: [

                  // ======================
                  // Seleccionar imagen
                  // ======================

                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Seleccionar imagen'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        setModalState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  if (selectedImage != null)
                    Image.file(
                      selectedImage!,
                      height: 120,
                    ),

                  const SizedBox(height: 16),

                  // ======================
                  // Porcentaje
                  // ======================

                  TextField(
                    controller: percentController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje primer pago',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ======================
                  // Fecha inicio
                  // ======================

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() {
                          validFrom = picked;
                        });
                      }
                    },
                    child: Text(validFrom == null
                        ? 'Seleccionar Fecha Inicio'
                        : 'Inicio: ${validFrom!.toLocal()}'),
                  ),

                  const SizedBox(height: 8),

                  // ======================
                  // Fecha fin
                  // ======================

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() {
                          validUntil = picked;
                        });
                      }
                    },
                    child: Text(validUntil == null
                        ? 'Seleccionar Fecha Fin'
                        : 'Fin: ${validUntil!.toLocal()}'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {

                    if (selectedImage == null ||
                        percentController.text.isEmpty ||
                        validFrom == null ||
                        validUntil == null) {
                      throw Exception(
                          'Todos los campos son obligatorios');
                    }

                    // ======================
                    // Subir a Cloudinary
                    // ======================

                    uploadedUrl =
                        await CloudinaryService.uploadImage(
                            selectedImage!);

                    if (uploadedUrl == null) {
                      throw Exception('Error subiendo imagen');
                    }

                    // ======================
                    // Crear QR en backend
                    // ======================

                    await OrderService.createQr(
                      qrUrl: uploadedUrl!,
                      percent: double.parse(
                          percentController.text),
                      validFrom: validFrom!,
                      validUntil: validUntil!,
                    );

                    Navigator.pop(context);
                    await _loadQrs();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content: Text('QR creado correctamente')),
                    );

                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                          content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
            appBar: AppBar(
                title: const Text('Gestión QR Pagos'),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _showCreateQrDialog,
                child: const Icon(Icons.add),
            ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _qrs.length,
        itemBuilder: (context, index) {
          final qr = _qrs[index];

        return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
            color: qr['is_active']
                ? Colors.green
                : Colors.grey.shade300,
            width: qr['is_active'] ? 2 : 1,
            ),
        ),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

                Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                    Text(
                    'QR ID: ${qr['id']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                    Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: qr['is_active']
                            ? Colors.green
                            : Colors.grey,
                        borderRadius:
                            BorderRadius.circular(12),
                    ),
                    child: Text(
                        qr['is_active']
                            ? 'ACTIVO'
                            : 'INACTIVO',
                        style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    ),
                ],
                ),

                const SizedBox(height: 8),

                Text(
                'Porcentaje: ${qr['first_payment_percent']}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 8),

                Image.network(
                qr['qr_image_url'],
                height: 120,
                ),

                const SizedBox(height: 12),

                if (qr['is_active'] == false)
                ElevatedButton(
                    onPressed: () => _activate(qr['id']),
                    child: const Text('Activar'),
                ),
            ],
            ),
        ),
        );
        },
      ),
    );
  }
}