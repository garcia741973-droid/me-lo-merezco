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
  String? _qrWarning;

  @override
  void initState() {
    super.initState();
    _loadQrs();
  }

  Future<void> _loadQrs() async {
    try {
      final data = await OrderService.fetchAdminQrs();

      String? warning;

      for (var qr in data) {
        if (qr['is_active'] == true) {
          final validUntil = DateTime.parse(qr['valid_until']);
          final diffDays = validUntil.difference(DateTime.now()).inDays;

          if (diffDays < 0) {
            warning = "❌ El QR activo está vencido";
          } else if (diffDays <= 7) {
            warning = "⚠ El QR activo vence en $diffDays días";
          }

          break;
        }
      }

      setState(() {
        _qrs = data;
        _loading = false;
        _qrWarning = warning;
      });

    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _activate(int id) async {
    await OrderService.activateQr(id);
    await _loadQrs();
  }

  Future<void> _showCreateQrDialog({Map<String, dynamic>? qr}) async {
  final percentController = TextEditingController(
    text: qr?['first_payment_percent']?.toString() ?? '',
  );

  DateTime? validFrom = qr != null
      ? DateTime.parse(qr['valid_from'])
      : null;

  DateTime? validUntil = qr != null
      ? DateTime.parse(qr['valid_until'])
      : null;

  File? selectedImage;

  String? uploadedUrl = qr?['qr_image_url'];

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

                  TextField(
                    controller: percentController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje primer pago',
                    ),
                  ),

                  const SizedBox(height: 16),

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

                    uploadedUrl =
                        await CloudinaryService.uploadImage(
                            selectedImage!);

                    if (uploadedUrl == null) {
                      throw Exception('Error subiendo imagen');
                    }

                    if (qr == null) {

                      await OrderService.createQr(
                        qrUrl: uploadedUrl!,
                        percent: double.parse(percentController.text),
                        validFrom: validFrom!,
                        validUntil: validUntil!,
                      );

                    } else {

                      await OrderService.updateQr(
                        id: qr['id'],
                        qrUrl: uploadedUrl!,
                        percent: double.parse(percentController.text),
                        validFrom: validFrom!,
                        validUntil: validUntil!,
                      );

                    }

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
                child: Text(qr == null ? 'Crear' : 'Guardar cambios'),
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
        body: Column(
          children: [

            if (_qrWarning != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _qrWarning!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _qrs.length,
                itemBuilder: (context, index) {

                  final qr = _qrs[index];

                  final validFrom = DateTime.parse(qr['valid_from']);
                  final validUntil = DateTime.parse(qr['valid_until']);
                  final now = DateTime.now();
                  final diffDays = validUntil.difference(now).inDays;

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

                          Text(
                            'Válido desde: ${validFrom.day}/${validFrom.month}/${validFrom.year}',
                          ),

                          Text(
                            'Válido hasta: ${validUntil.day}/${validUntil.month}/${validUntil.year}',
                          ),

                          const SizedBox(height: 6),

                          if (diffDays < 0)
                            const Text(
                              '❌ QR vencido',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            )
                          else if (diffDays <= 7)
                            Text(
                              '⚠ Vence en $diffDays días',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            )
                          else
                            Text(
                              'Vigente ($diffDays días restantes)',
                              style: const TextStyle(
                                  color: Colors.green),
                            ),

                          const SizedBox(height: 10),

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

                            const SizedBox(height: 8),

                            if (qr['is_active'] == false)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () {
                                  _showCreateQrDialog(qr: qr);
                                },
                                child: const Text('Editar'),
                              ),

                              const SizedBox(height: 8),

                              if (qr['is_active'] == false)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () async {

                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Eliminar QR"),
                                        content: const Text(
                                          "¿Seguro que deseas eliminar este QR?"
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Cancelar"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Eliminar"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {

                                      await OrderService.deleteQr(qr['id']);

                                      await _loadQrs();

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("QR eliminado"),
                                        ),
                                      );
                                    }

                                  },
                                  child: const Text("Eliminar"),
                                ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
    );
  }
}