import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void success(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  static void error(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  static void normal(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      // icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }
}
