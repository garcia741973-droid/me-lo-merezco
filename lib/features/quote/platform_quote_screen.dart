import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';

class PlatformQuoteScreen extends StatefulWidget {
  final String platform;

  const PlatformQuoteScreen({
    super.key,
    required this.platform,
  });

  @override
  State<PlatformQuoteScreen> createState() =>
      _PlatformQuoteScreenState();
}

class _PlatformQuoteScreenState
    extends State<PlatformQuoteScreen> {

  final _urlController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCurrency;
  String? _selectedSize;

  Map<String, dynamic>? _result;
  bool _loading = false;

  final String baseUrl =
      'https://me-lo-merezco-backend.onrender.com';

  // 🔷 Color por plataforma
  Color _getPlatformColor() {
    switch (widget.platform.toLowerCase()) {
      case 'shein':
        return Colors.black;
      case 'amazon':
        return const Color(0xFFFF9900);
      case 'aliexpress':
        return Colors.red;
      case 'temu':
        return const Color(0xFFB71C1C);
      default:
        return Colors.blue;
    }
  }

  // 🔹 Validación URL
  bool _validateUrl(String url) {
    final platform = widget.platform.toLowerCase();

    if (platform == 'shein') return url.contains('-p-');
    if (platform == 'amazon') return url.contains('/dp/');
    if (platform == 'aliexpress') return url.contains('/item/');
    if (platform == 'temu') return url.contains('-g-');

    return false;
  }

  // 🔹 Extraer nombre Shein
  String _extractSheinName(String url) {
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.last;

      String name = lastSegment.replaceAll('.html', '');
      final index = name.lastIndexOf('-p-');
      if (index != -1) {
        name = name.substring(0, index);
      }

      return name.replaceAll('-', ' ');
    } catch (_) {
      return '';
    }
  }
  // 🔹 Extraer nombre amazon
String _extractAmazonName(String url) {
  try {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;

    final dpIndex = segments.indexOf('dp');

    if (dpIndex > 0) {
      String name = segments[dpIndex - 1];
      name = name.replaceAll('-', ' ');
      return name;
    }

    return '';
  } catch (_) {
    return '';
  }
}

// 🔹 Extraer nombre AliExpress
String _extractAliExpressName(String url) {
  try {
    final regex = RegExp(r'/item/(\d+)\.html');
    final match = regex.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'AliExpress Item $id';
    }

    return 'AliExpress Item';
  } catch (_) {
    return 'AliExpress Item';
  }
}

// 🔹 Extraer nombre TEMU
String _extractTemuName(String url) {
  try {
    final uri = Uri.parse(url);
    final lastSegment = uri.pathSegments.last;

    String name = lastSegment.replaceAll('.html', '');

    final index = name.lastIndexOf('-g-');
    if (index != -1) {
      name = name.substring(0, index);
    }

    return name.replaceAll('-', ' ');
  } catch (_) {
    return '';
  }
}


  // 🔹 Calcular
  Future<void> _calculate() async {
  if (_urlController.text.isEmpty ||
      _priceController.text.isEmpty ||
      _selectedCurrency == null ||
      _selectedSize == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Completa todos los campos')),
    );
    return;
  }

  if (!_validateUrl(_urlController.text)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL inválida para esta plataforma')),
    );
    return;
  }

  // 🔹 Normalizar decimal (acepta coma y punto)
  final rawPrice =
      _priceController.text.trim().replaceAll(',', '.');
  final parsedPrice = double.tryParse(rawPrice);

  if (parsedPrice == null || parsedPrice <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Precio inválido')),
    );
    return;
  }

  setState(() => _loading = true);

  final token = await AuthService().getToken();

  final res = await http.post(
    Uri.parse('$baseUrl/quote'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "platform": widget.platform.toLowerCase(),
      "url": _urlController.text,
      "base_price": parsedPrice,
      "currency": _selectedCurrency,
      "size": _selectedSize,
    }),
  );

  setState(() => _loading = false);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    final platform = widget.platform.toLowerCase();

    if (platform == 'shein') {
      data['product_name'] =
          _extractSheinName(_urlController.text);
    }

    if (platform == 'amazon') {
      data['product_name'] =
          _extractAmazonName(_urlController.text);
    }

if (platform == 'aliexpress') {
  data['product_name'] =
      _extractAliExpressName(_urlController.text);
}

if (platform == 'temu') {
  data['product_name'] =
      _extractTemuName(_urlController.text);
}


    setState(() => _result = data);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error calculando cotización')),
    );
  }
}


  // 🔹 Agregar al carrito
    Future<void> _addToCart() async {

      // 🔒 BLOQUEO VISITANTE
      if (AuthService().currentUser == null) {
        _showAuthRequiredDialog();
        return;
      }

      if (_result == null) return;

      final token = await AuthService().getToken();

      if (token == null) {
        _showAuthRequiredDialog();
        return;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/orders/add-quote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "product_name": _result!['product_name'],
          "product_url": _urlController.text,
          "platform": widget.platform.toLowerCase(),
          "size": _selectedSize,
          "base_price_original": _result!['base_price_original'],
          "currency_original": _result!['currency_original'],
          "base_price_bob": _result!['base_price_bob'],
          "import_percent": _result!['import_percent'],
          "margin_percent": _result!['margin_percent'],
          "total_final_bob": _result!['total_final_bob'],
        }),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200
                ? 'Agregado al carrito'
                : 'Error al agregar al carrito',
          ),
        ),
      );
    }

        void _showAuthRequiredDialog() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Acceso requerido"),
          content: const Text(
            "Lo sentimos esta función es solo permitido para usuarios registrados, por favor inicia una sesión o registrate. Gracias",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text("Iniciar sesión"),
            ),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final platformColor = _getPlatformColor();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // 🔷 HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: platformColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.platform.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            title: Text('Instrucciones'),
                            content: Text(
                              '• Utiliza navegador para ver tu producto.\n'
                              '• por ejemplo http://cl.shein.com u otra.\n'
                              '• No olvides configurar esta página para \n'
                              '• latino america de preferencia chile.\n'
                              '• Pega el enlace completo del producto que elegiste.\n'
                              '• El URL es la barra del navegador empieza con http://....\n'
                              '• De no ser un producto de esa platafomra te saldrá error.\n'
                              '• pequeño (accesorios), medido (ropa, mochilas, etc) y grande (zapatos, electro.)',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔷 FORMULARIO
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text('URL'),
                        TextField(controller: _urlController),

                        const SizedBox(height: 16),

                        const Text('Moneda'),
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'CLP', child: Text('CLP')),
                            DropdownMenuItem(value: 'BOB', child: Text('BOB')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedCurrency = v),
                        ),

                        const SizedBox(height: 16),

                        const Text('Categoría'),
                        DropdownButtonFormField<String>(
                          value: _selectedSize,
                          items: const [
                            DropdownMenuItem(value: 'small', child: Text('Pequeño')),
                            DropdownMenuItem(value: 'medium', child: Text('Mediano')),
                            DropdownMenuItem(value: 'large', child: Text('Grande')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedSize = v),
                        ),

                        const SizedBox(height: 16),

                        const Text('Precio'),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: platformColor,
                            ),
                            onPressed: _loading ? null : _calculate,
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('CALCULAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔷 RESULTADO
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _ExpandableText(
                            text: _result!['product_name'] ?? '',
                          ),

                          const SizedBox(height: 16),

                          Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildRow(
      'Precio base',
      '${_result!['base_price_original']} ${_result!['currency_original']}',
    ),
    Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        '${_result!['base_price_bob'].toStringAsFixed(2)} Bs',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
    ),
  ],
),


_buildRow(
  'Importación',
  '${_result!['import_cost'].toStringAsFixed(2)} Bs',
),

_buildRow(
  'Margen',
  '${_result!['margin_cost'].toStringAsFixed(2)} Bs',
),


                          const Divider(height: 24),

                          _buildRow(
                            'TOTAL',
                            '${_result!['total_final_bob'].toStringAsFixed(2)} Bs',
                            bold: true,
                            color: platformColor,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.shopping_cart),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: platformColor,
                              ),
                              onPressed: _addToCart,
                              label: const Text('Agregar al carrito'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔷 Expandible
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() =>
      _ExpandableTextState();
}

class _ExpandableTextState
    extends State<_ExpandableText> {

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: expanded ? null : 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (widget.text.length > 60)
          GestureDetector(
            onTap: () =>
                setState(() => expanded = !expanded),
            child: Text(
              expanded ? 'Ver menos' : 'Ver más',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
