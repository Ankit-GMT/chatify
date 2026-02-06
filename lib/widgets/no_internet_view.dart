import 'package:chatify/services/network_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 90, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                "No Internet Connection",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please check your internet and try again",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.find<NetworkController>().retry(),
                child: const Text("Retry"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
