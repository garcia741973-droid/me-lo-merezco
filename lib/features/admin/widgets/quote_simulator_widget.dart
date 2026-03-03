import 'package:flutter/material.dart';
import '../../../core/services/quote_simulator_service.dart';

class QuoteSimulatorWidget extends StatefulWidget {
  const QuoteSimulatorWidget({super.key});

  @override
  State<QuoteSimulatorWidget> createState() =>
      _QuoteSimulatorWidgetState();
}

class _QuoteSimulatorWidgetState
    extends State<QuoteSimulatorWidget> {

  final TextEditingController _basePriceCtrl =
      TextEditingController();

  String _selectedCurrency = 'USD';
  String? _selectedCategory;

  bool _loading = true;

  double usdtToBob = 0;
  double usdtToUsd = 0;
  double usdtToClp = 0;
  double marginPercent = 0;

  Map<String, double> importCategories = {};

  double? resultBob;
  double? importCost;
  double? marginCost;
  double? basePriceBob;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

    Future<void> _loadConfig() async {
    try {
        final config =
            await QuoteSimulatorService.fetchConfig();

        setState(() {

        // 🔵 Limpiar antes
        importCategories.clear();

        // 🔵 Tasas
        for (var r in config['rates']) {
            if (r['currency'] == 'BOB') {
            usdtToBob = double.parse(r['rate_to_bob'].toString());
            }
            if (r['currency'] == 'USD') {
            usdtToUsd = double.parse(r['rate_to_bob'].toString());
            }
            if (r['currency'] == 'CLP') {
            usdtToClp = double.parse(r['rate_to_bob'].toString());
            }
        }

        // 🔵 Margen
        marginPercent =
            marginPercent =
                double.tryParse(config['margin_percent'].toString()) ?? 0;

        // 🔵 Categorías
        for (var c in config['import_categories']) {
            importCategories[c['key']] =
                double.parse(c['percent'].toString());
        }

        if (importCategories.isNotEmpty) {
            _selectedCategory = importCategories.keys.first;
        }

        _loading = false;
        });

    } catch (e) {
      print("ERROR LOAD CONFIG: $e");  
        setState(() => _loading = false);
    }
    }

  void _calculate() {

    final base =
        double.tryParse(_basePriceCtrl.text.replaceAll(',', '.')) ?? 0;

    if (base <= 0 ||
        usdtToBob == 0 ||
        usdtToUsd == 0 ||
        usdtToClp == 0 ||
        _selectedCategory == null) {
      setState(() {
        resultBob = null;
      });
      return;
    }

    double priceUSDT = 0;

    if (_selectedCurrency == 'USD') {
      priceUSDT = base / usdtToUsd;
    } else if (_selectedCurrency == 'CLP') {
      priceUSDT = base / usdtToClp;
    } else {
      priceUSDT = base / usdtToBob;
    }

    basePriceBob = priceUSDT * usdtToBob;

    final importPercent =
        importCategories[_selectedCategory!] ?? 0;

    importCost = basePriceBob! * (importPercent / 100);

    marginCost =
        basePriceBob! * (marginPercent / 100);

    final total =
        basePriceBob! + importCost! + marginCost!;

    resultBob =
        (total * 100).round() / 100;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
Text("DEBUG categorias: ${importCategories.keys.toList()}"),
          const Text(
            'Simulador de Cotización',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // 🔵 Precio base
          TextField(
            controller: _basePriceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio base original',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _calculate(),
          ),

          const SizedBox(height: 12),

          // 🔵 Moneda
            SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                isExpanded: true,
                items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'CLP', child: Text('CLP')),
                DropdownMenuItem(value: 'BOB', child: Text('BOB')),
                ],
                onChanged: (v) {
                setState(() {
                    _selectedCurrency = v!;
                });
                _calculate();
                },
                decoration: const InputDecoration(
                labelText: 'Moneda',
                border: OutlineInputBorder(),
                ),
            ),
),

          const SizedBox(height: 12),

          // 🔵 Categoría dinámica
          if (importCategories.isNotEmpty)
            SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: importCategories.keys
                    .map(
                    (key) => DropdownMenuItem<String>(
                        value: key,
                        child: Text(
                        "$key (${importCategories[key]}%)",
                        ),
                    ),
                    )
                    .toList(),
                onChanged: (value) {
                setState(() {
                    _selectedCategory = value;
                });
                _calculate();
                },
                decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
                ),
            ),
            ),

          const SizedBox(height: 20),

          if (resultBob != null) ...[
            const Divider(),

            Text(
              'Base convertido a BOB: ${basePriceBob!.toStringAsFixed(2)}',
            ),

            Text(
              'Importación (${importCategories[_selectedCategory]}%): '
              '${importCost!.toStringAsFixed(2)}',
            ),

            Text(
              'Margen ($marginPercent%): '
              '${marginCost!.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 8),

            Text(
              'TOTAL FINAL: ${resultBob!.toStringAsFixed(2)} Bs',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}