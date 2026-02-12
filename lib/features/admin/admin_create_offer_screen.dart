import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/cloudinary_service.dart';

class AdminCreateOfferScreen extends StatefulWidget {
  const AdminCreateOfferScreen({super.key});

  @override
  State<AdminCreateOfferScreen> createState() =>
      _AdminCreateOfferScreenState();
}

class _AdminCreateOfferScreenState extends State<AdminCreateOfferScreen> {
  // ---------------- CONTROLLERS ----------------
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  // ---------------- FECHAS ----------------
  DateTime? startsAt;
  DateTime? endsAt;

  // ---------------- IMAGEN ----------------
  File? _imageFile;
  String? _imageUrl;
  bool _uploadingImage = false;

  bool isLoading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // =========================
  // PICK IMAGE
  // =========================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imageUrl = null;
      });
    }
  }

  // =========================
  // UPLOAD IMAGE (CLOUDINARY)
  // =========================
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _uploadingImage = true);

    final url =
        await CloudinaryService.uploadImage(_imageFile!);

    if (!mounted) return;

    setState(() {
      _uploadingImage = false;
      _imageUrl = url;
    });

    if (url == null) {
      _showMessage('Error subiendo imagen');
    }
  }

  // =========================
  // CREATE OFFER
  // =========================
  Future<void> _createOffer() async {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final priceText = priceCtrl.text.trim();

    if (title.isEmpty) {
      _showMessage('El título es obligatorio');
      return;
    }

    if (priceText.isEmpty) {
      _showMessage('El precio es obligatorio');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      _showMessage('Precio inválido');
      return;
    }

    if (_imageUrl == null) {
      _showMessage('Debes subir una imagen');
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await AuthService().getToken();

      final res = await http.post(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/offers',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description.isEmpty ? null : description,
          'price': price,
          'image_url': _imageUrl,
          'starts_at': startsAt?.toIso8601String(),
          'ends_at': endsAt?.toIso8601String(),
        }),
      );

      if (res.statusCode == 201) {
        _showMessage('Oferta creada correctamente');
        Navigator.pop(context, true);
      } else {
        _showMessage('Error al crear la oferta');
      }
    } catch (_) {
      _showMessage('Error de conexión');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =========================
  // DATE PICKER
  // =========================
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startsAt = picked;
      } else {
        endsAt = picked;
      }
    });
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear oferta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  hintText: 'Ej: 199.99',
                ),
              ),
              const SizedBox(height: 20),

              // ---------- FECHAS ----------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _pickDate(isStart: true),
                      child: Text(
                        startsAt == null
                            ? 'Fecha inicio'
                            : 'Inicio: ${startsAt!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _pickDate(isStart: false),
                      child: Text(
                        endsAt == null
                            ? 'Fecha fin'
                            : 'Fin: ${endsAt!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------- IMAGEN ----------
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 180,
                  fit: BoxFit.cover,
                ),

              if (_imageUrl != null) ...[
                const SizedBox(height: 12),
                Image.network(
                  _imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ],

              const SizedBox(height: 12),

              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Elegir imagen'),
                onPressed: _pickImage,
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                icon: _uploadingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text('Subir imagen'),
                onPressed:
                    (_imageFile == null || _uploadingImage)
                        ? null
                        : _uploadImage,
              ),

              const SizedBox(height: 30),

              // ---------- CREATE ----------
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      onPressed: _createOffer,
                      child: const Text('Crear oferta'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
