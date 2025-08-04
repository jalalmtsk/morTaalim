// connectivity_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/ConnectivityManager/Connectivity_Manager.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Provider.of<ConnectivityService>(context);
    return Icon(
      connectivity.isConnected ? Icons.wifi : Icons.wifi_off,
      color: connectivity.isConnected ? Colors.green : Colors.grey,
    );
  }
}