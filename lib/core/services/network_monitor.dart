import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {

  static void start(BuildContext context) {

    Connectivity().onConnectivityChanged.listen((result) {

      if (result == ConnectivityResult.none) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sin conexión a internet"),
            duration: Duration(seconds: 3),
          ),
        );

      }

    });

  }

}