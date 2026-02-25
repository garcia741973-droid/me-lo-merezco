import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/cloudinary_service.dart';

class AdminCreateOfferScreen extends StatefulWidget {
  final Map<String, dynamic>? offer;

  const AdminCreateOfferScreen({
    super.key,
    this.offer,
  });

  @override
  State<AdminCreateOfferScreen> createState() =>
      _AdminCreateOfferScreenState();
}

class _AdminCreateOfferScreenState
    extends State<AdminCreateOfferScreen> {


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

  // ---------------- CATEGORÍAS ----------------
  int? selectedCategoryId;
  List<dynamic> categories = [];
  bool loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

if (widget.offer != null) {
  titleCtrl.text = widget.offer!['title'] ?? '';
  descCtrl.text = widget.offer!['description'] ?? '';
  priceCtrl.text =
      widget.offer!['price']?.toString() ?? '';
  selectedCategoryId = widget.offer!['category_id'];
}


  }

  Future<void> _loadCategories() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/categories',
        ),
      );

      if (res.statusCode == 200) {
        setState(() {
          categories = jsonDecode(res.body);
          loadingCategories = false;
        });
      }
    } catch (_) {
      setState(() => loadingCategories = false);
    }
  }

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

final normalizedPriceText =
    priceText.replaceAll(',', '.');

final price =
    double.tryParse(normalizedPriceText);

    if (price == null) {
      _showMessage('Precio inválido');
      return;
    }

    if (_imageUrl == null) {
      _showMessage('Debes subir una imagen');
      return;
    }

    if (selectedCategoryId == null) {
      _showMessage('Debes seleccionar una categoría');
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await AuthService().getToken();

 final uri = widget.offer == null
    ? Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/admin/offers')
    : Uri.parse(
        'https://me-lo-merezco-backend.onrender.com/admin/offers/${widget.offer!['id']}');

final body = jsonEncode({
  'title': title,
  'description': description.isEmpty ? null : description,
  'price': price,
  'image_url': _imageUrl,
  'starts_at': startsAt?.toIso8601String(),
  'ends_at': endsAt?.toIso8601String(),
  'category_id': selectedCategoryId,
});

final res = widget.offer == null
    ? await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      )
    : await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );


      if (res.statusCode == 201 || res.statusCode == 200) {
  _showMessage(
      widget.offer == null
          ? 'Oferta creada correctamente'
          : 'Oferta actualizada correctamente');
  Navigator.pop(context, true);
} else {
  _showMessage('Error al guardar la oferta');
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

              // ---------- CATEGORÍA ----------
              loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
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
