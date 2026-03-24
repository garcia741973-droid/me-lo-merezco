import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final Connectivity _connectivity = Connectivity();

  bool _isConnected = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Escucha cambios de red
    _connectivity.onConnectivityChanged.listen((_) async {
      final connected = await _hasInternet();
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    _checkInitial();

    // Chequeo periódico
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final connected = await _hasInternet();
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await http
          .get(Uri.parse('https://me-lo-merezco-backend.onrender.com/offers'))
          .timeout(const Duration(seconds: 3));

      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkInitial() async {
    final connected = await _hasInternet();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

    @override
    Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Stack(
        children: [
        widget.child,

        AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isConnected ? -100 : bottomSafe + 20,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isConnected ? 0 : 1,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                    BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    ),
                ],
                ),
                child: Row(
                children: const [
                    Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                    child: Text(
                        'Sin conexión a internet',
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        ),
                    ),
                    ),
                ],
                ),
            ),
            ),
        ),
        ],
    );
    }
}