import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SheinWebViewScreen extends StatefulWidget {
  final String productUrl;

  const SheinWebViewScreen({
    super.key,
    required this.productUrl,
  });

  @override
  State<SheinWebViewScreen> createState() => _SheinWebViewScreenState();
}

class _SheinWebViewScreenState extends State<SheinWebViewScreen> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _dataSent = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();

    final mobileUrl =
        widget.productUrl.replaceFirst('www.shein.com', 'm.shein.com');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SheinChannel',
onMessageReceived: (message) {
  final data = jsonDecode(message.message);
  print("HTML DEBUG:");
  print(data);
},



      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            if (!mounted) return;

            await Future.delayed(const Duration(seconds: 2));

            setState(() => _loading = false);
            _tryExtractRepeatedly();
          },
        ),
      )
      ..loadRequest(Uri.parse(mobileUrl));
  }

  void _tryExtractRepeatedly() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _dataSent) {
        timer.cancel();
        return;
      }

      _attempts++;
      await _extractProductData();

      if (_attempts >= 20 && !_dataSent) {
        timer.cancel();
        Navigator.pop(context, {
          'error': 'No se pudo obtener información del producto',
        });
      }
    });
  }

  Future<void> _extractProductData() async {
  const js = """
  (function() {
    try {

      const pageText = document.body.innerText;

      if (!pageText) return;

      // Buscar primer precio tipo 12.99 o 9.49
      const priceMatch = pageText.match(/\\d+\\.\\d{2}/);

      if (!priceMatch) return;

      const price = parseFloat(priceMatch[0]);

      if (!price || price <= 0) return;

      // Intentar obtener título desde h1
      const h1 = document.querySelector('h1');
      let name = '';

      if (h1) {
        name = h1.innerText.trim();
      }

      if (!name || name.length < 5) {
        // Si no encuentra título válido, usar primeras palabras del texto
        name = pageText.substring(0, 60);
      }

      SheinChannel.postMessage(JSON.stringify({
        name: name,
        price: price
      }));

    } catch (e) {
      SheinChannel.postMessage(JSON.stringify({
        error: "text_scan_error"
      }));
    }
  })();
  """;

  await _controller.runJavaScript(js);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
