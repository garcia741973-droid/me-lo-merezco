import 'package:flutter/material.dart';
import '../../../core/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/quote_simulator_widget.dart';

class AdminItemReviewSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onUpdated;

  const AdminItemReviewSheet({
    super.key,
    required this.item,
    required this.onUpdated,
  });

  @override
  State<AdminItemReviewSheet> createState() =>
      _AdminItemReviewSheetState();
}

class _AdminItemReviewSheetState
    extends State<AdminItemReviewSheet> {

  final TextEditingController _messageController =
      TextEditingController();
  final TextEditingController _priceController =
      TextEditingController();

  bool requestSize = false;
  bool requestColor = false;
  bool requestNotes = false;

  @override
  Widget build(BuildContext context) {
    final clientSpecs =
        widget.item['client_specs'] as Map<String, dynamic>? ?? {};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 🔴 Barra superior con botón cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Revisión del ítem",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

Center(
  child: Container(
    width: 40,
    height: 5,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.grey[400],
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),


              /// 🔵 Título
              Text(
                widget.item['product_name'] ?? '',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text("Precio actual: Bs ${widget.item['price']}"),
              Text("Estado: ${widget.item['status']}"),

              const Divider(height: 30),

                if (widget.item['source_type'] == 'offer') ...[
                const Divider(height: 30),
                const Text(
                    "Datos de la oferta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (widget.item['offer_image'] != null)
                    ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                        widget.item['offer_image'],
                        height: 180,
                        fit: BoxFit.cover,
                    ),
                    ),

                const SizedBox(height: 8),

                if (widget.item['offer_platform'] != null)
                    Text("Tienda: ${widget.item['offer_platform']}"),

                if (widget.item['offer_size'] != null)
                    Text("Talla base: ${widget.item['offer_size']}"),

                if (widget.item['offer_base_price'] != null)
                    Text("Costo base: ${widget.item['offer_base_price']}"),

                if (widget.item['offer_cost_import_percent'] != null)
                  Text(
                    "Importación: ${widget.item['offer_cost_import_percent']}%",
                  ),

                if (widget.item['offer_cost_margin_percent'] != null)
                  Text(
                    "Margen: ${widget.item['offer_cost_margin_percent']}%",
                  ),

                if (widget.item['offer_source_url'] != null &&
                    widget.item['offer_source_url'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        "URL original:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final uri =
                              Uri.parse(widget.item['offer_source_url']);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_new,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.item['offer_source_url'],
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],


              /// 🔵 URL
              if (widget.item['product_url'] != null &&
                  widget.item['product_url']
                      .toString()
                      .isNotEmpty) ...[
                const Text(
                  "Producto:",
                  style:
                      TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(
                    widget.item['product_url']),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(
                        widget.item['product_url']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode
                              .externalApplication);
                    }
                  },
                  child:
                      const Text("Abrir en navegador"),
                ),
                const Divider(height: 30),
              ],

                if (widget.item['meta'] != null) ...[
                const Divider(height: 30),
                const Text(
                    "Datos técnicos",
                    style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (widget.item['meta']['platform'] != null)
                    Text("Plataforma: ${widget.item['meta']['platform']}"),

                if (widget.item['meta']['base_price_original'] != null)
                    Text(
                    "Precio original: ${widget.item['meta']['base_price_original']} "
                    "${widget.item['meta']['currency_original'] ?? ''}",
                    ),

                if (widget.item['meta']['size'] != null)
                    Text("Talla base usada: ${widget.item['meta']['size']}"),

                if (widget.item['meta']['import_percent'] != null)
                    Text("Importación: ${widget.item['meta']['import_percent']}%"),

                if (widget.item['meta']['margin_percent'] != null)
                    Text("Margen: ${widget.item['meta']['margin_percent']}%"),
                ],              

                // 🔵 Simulador solo para cotizaciones
                Text("DEBUG source_type: ${widget.item['source_type']}"),
                if (widget.item['source_type'] == 'quote') ...[
                  const SizedBox(height: 20),
                  const QuoteSimulatorWidget(),
                  const Divider(height: 30),
                ],

              /// 🔵 Especificaciones cliente
              const Text(
                "Especificaciones del cliente",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (clientSpecs.isEmpty)
                const Text(
                  "⚠ No ha enviado especificaciones.",
                  style:
                      TextStyle(color: Colors.orange),
                )
              else
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: clientSpecs.entries
                      .map((e) => Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                    vertical: 4),
                            child: Text(
                                "${e.key}: ${e.value}"),
                          ))
                      .toList(),
                ),

              const Divider(height: 30),

              /// 🔵 Formulario condición
              const Text(
                "Rechazo condicional",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                    labelText: "Mensaje al cliente"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                decoration: const InputDecoration(
                    labelText:
                        "Precio ajustado (opcional)"),
              ),

              const SizedBox(height: 16),

              const Text(
                "Solicitar:",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),

              CheckboxListTile(
                value: requestSize,
                onChanged: (v) =>
                    setState(() =>
                        requestSize = v ?? false),
                title: const Text("Talla"),
              ),

              CheckboxListTile(
                value: requestColor,
                onChanged: (v) =>
                    setState(() =>
                        requestColor = v ?? false),
                title: const Text("Color"),
              ),

              CheckboxListTile(
                value: requestNotes,
                onChanged: (v) =>
                    setState(() =>
                        requestNotes = v ?? false),
                title: const Text("Observaciones"),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitCondition,
                  child:
                      const Text("Enviar condición"),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCondition() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("El mensaje es obligatorio")),
      );
      return;
    }

    double? adjustedPrice;

    if (_priceController.text.isNotEmpty) {
      adjustedPrice = double.tryParse(
          _priceController.text.replaceAll(
              ',', '.'));
    }

    List<Map<String, dynamic>> requiredFields =
        [];

    if (requestSize) {
      requiredFields.add({
        "key": "size",
        "label": "Talla",
        "type": "text",
      });
    }

    if (requestColor) {
      requiredFields.add({
        "key": "color",
        "label": "Color",
        "type": "text",
      });
    }

    if (requestNotes) {
      requiredFields.add({
        "key": "notes",
        "label": "Observaciones",
        "type": "text",
      });
    }

    try {
      await OrderService.conditionalRejectItem(
        itemId: widget.item['id'],
        message:
            _messageController.text.trim(),
        adjustedPrice: adjustedPrice,
        requiredFields: requiredFields,
      );

      widget.onUpdated();
      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Error enviando condición")),
      );
    }
  }
}