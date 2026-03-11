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
  final basePriceCtrl = TextEditingController();
  final importPercentCtrl = TextEditingController();
  final marginPercentCtrl = TextEditingController();
  final platformCtrl = TextEditingController();
  final sourceUrlCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  final currencyCtrl = TextEditingController();
  final colorCtrl = TextEditingController();

  final finalPriceCtrl = TextEditingController(); // ✅ ESTE ES NUEVO

  // ---------------- FECHAS ----------------
  DateTime? startsAt;
  DateTime? endsAt;

  // ---------------- IMAGEN ----------------
  File? _imageFile;
  String? _imageUrl;
  bool _uploadingImage = false;

  bool isLoading = false;

// ---------------- EXCHANGE RATES ----------------
  double? rateUsd;
  double? rateClp;
  double? priceBob;
  bool loadingRate = false;

  String selectedCurrency = 'USD';

  // ---------------- CATEGORÍAS ----------------
  int? selectedCategoryId;
  List<dynamic> categories = [];
  bool loadingCategories = true;

  @override
  void initState() {
    super.initState();


    _loadCategories();
    _loadExchangeRates();

    Future.delayed(const Duration(milliseconds: 200), () {
      _calculateBob();
    });    

if (widget.offer != null) {
  titleCtrl.text = widget.offer!['title'] ?? '';
  descCtrl.text = widget.offer!['description'] ?? '';

  finalPriceCtrl.text =
        widget.offer!['price']?.toString() ?? '';

  selectedCategoryId = widget.offer!['category_id'];

  basePriceCtrl.text =
      widget.offer!['base_purchase_price']?.toString() ?? '';

//  importPercentCtrl.text =
//    widget.offer!['cost_import_percent']?.toString() ?? '';

//  marginPercentCtrl.text =
//      widget.offer!['cost_margin_percent']?.toString() ?? '';

  platformCtrl.text =
      widget.offer!['platform'] ?? '';

  sourceUrlCtrl.text =
      widget.offer!['source_url'] ?? '';

  sizeCtrl.text =
      widget.offer!['size'] ?? '';

  currencyCtrl.text =
      widget.offer!['currency_original'] ?? '';

  colorCtrl.text =
      widget.offer!['color'] ?? '';

  _imageUrl = widget.offer!['image_url'];

  _calculateBob();

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

  // =========================
  // LOAD EXCHANGE RATES
  // =========================
    Future<void> _loadExchangeRates() async {
      try {
        setState(() => loadingRate = true);

        final token = await AuthService().getToken();

        final res = await http.get(
          Uri.parse(
            'https://me-lo-merezco-backend.onrender.com/exchange/active',
          ),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        print(res.body);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          setState(() {
            rateUsd = (data['USD'] as num?)?.toDouble();
            rateClp = (data['CLP'] as num?)?.toDouble();
          });

          _calculateBob();
        }
      } catch (e) {
        debugPrint('Error cargando tasas: $e');
      } finally {
        if (mounted) {
          setState(() => loadingRate = false);
        }
      }
    }

  // =========================
  // CALCULAR PRECIO EN BOB
  // =========================
      void _calculateBob() {
        final base = double.tryParse(
              basePriceCtrl.text.replaceAll(',', '.'),
            ) ??
            0;

        if (base <= 0) {
          setState(() => priceBob = null);
          return;
        }

        double? result;

        if (selectedCurrency == 'BOB') {
          result = base;
        }

        if (selectedCurrency == 'USD' && rateUsd != null) {
          result = base * rateUsd!;
        }

        if (selectedCurrency == 'CLP' && rateClp != null) {
          result = base * rateClp!;
        }

        setState(() {
          priceBob = result;
        });
      }
// =========================
// CALCULAR PRECIO FINAL (Modelo A)
// =========================
  double _calculateFinalPrice() {
  final base = priceBob ??
      double.tryParse(
        basePriceCtrl.text.replaceAll(',', '.'),
      ) ??
      0;

  final importPercent = double.tryParse(
        importPercentCtrl.text.replaceAll(',', '.'),
      ) ??
      0;

  final marginPercent = double.tryParse(
        marginPercentCtrl.text.replaceAll(',', '.'),
      ) ??
      0;

  final importValue = base * importPercent / 100;
  final marginValue = base * marginPercent / 100;

  return base + importValue + marginValue;
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

    final price =
    double.tryParse(finalPriceCtrl.text.replaceAll(',', '.')) ??
    _calculateFinalPrice();

    if (price <= 0) {
      _showMessage('El precio calculado no puede ser 0');
      return;
    }

    if (title.isEmpty) {
      _showMessage('El título es obligatorio');
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
  'description': description,
  'price': price,
  'image_url': _imageUrl,
  'starts_at': startsAt?.toIso8601String(),
  'ends_at': endsAt?.toIso8601String(),
  'category_id': selectedCategoryId,

  'base_purchase_price': double.tryParse(
      basePriceCtrl.text.replaceAll(',', '.')),

  'cost_import_percent': double.tryParse(
      importPercentCtrl.text.replaceAll(',', '.')),

  'cost_margin_percent': double.tryParse(
      marginPercentCtrl.text.replaceAll(',', '.')),

  'platform': platformCtrl.text,
  'source_url': sourceUrlCtrl.text,
  'size': sizeCtrl.text,
  'currency_original': selectedCurrency,
  'color': colorCtrl.text,
});


print("======= URL =======");
print(uri);
print("===================");

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

print("======= BODY ENVIADO =======");
print(body);
print("============================"); 

print("======= RESPONSE STATUS =======");
print(res.statusCode);


print("======= RESPONSE BODY =======");
print(res.body);
print("==============================");

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


    double baseBs = priceBob ?? 0;

    double importPercent =
        double.tryParse(importPercentCtrl.text.replaceAll(',', '.')) ?? 0;

    double marginPercent =
        double.tryParse(marginPercentCtrl.text.replaceAll(',', '.')) ?? 0;

    double importCost = baseBs * importPercent / 100;
    double marginCost = baseBs * marginPercent / 100;

    double finalPrice = baseBs + importCost + marginCost;

      if (finalPriceCtrl.text.isEmpty && finalPrice > 0) {
        finalPriceCtrl.text = finalPrice.toStringAsFixed(0);
      }

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
                  controller: basePriceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio proveedor',
                  ),
                  onChanged: (_) {
                    _calculateBob();
                    setState(() {});
                  },
                ),

//              const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Moneda proveedor',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'CLP', child: Text('CLP')),
                    DropdownMenuItem(value: 'BOB', child: Text('BOB')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCurrency = value!;
                      priceBob = null; // reinicia cálculo anterior
                    });

                    _calculateBob();
                  },
                ),

                const SizedBox(height: 12),

                if (priceBob != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversión automática',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Precio en Bs: ${priceBob!.toStringAsFixed(2)}'),
                        if (selectedCurrency == 'USD' && rateUsd != null)
                          Text('Tipo cambio USD: $rateUsd'),
                        if (selectedCurrency == 'CLP' && rateClp != null)
                          Text('Tipo cambio CLP: $rateClp'),
                      ],
                    ),
                  ),              

                  if (priceBob != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Resumen del cálculo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text('Costo base Bs: ${baseBs.toStringAsFixed(2)}'),
                          Text('Importación: ${importCost.toStringAsFixed(2)}'),
                          Text('Margen: ${marginCost.toStringAsFixed(2)}'),

                          const Divider(),

                          Text(
                            'Precio final Bs: ${finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        ],
                      ),
                    ),

                const SizedBox(height: 12),

                TextField(
                  controller: importPercentCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Importación %',
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: marginPercentCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Margen %',
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Precio final: ${_calculateFinalPrice().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: finalPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio final de venta (editable)',
                    border: OutlineInputBorder(),
                  ),
                ),                

              const SizedBox(height: 30),

              const Text(
                'Datos de origen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: platformCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tienda / Plataforma',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: sourceUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL del producto',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Talla disponible',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color',
                ),
              ),

              const SizedBox(height: 12),

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
