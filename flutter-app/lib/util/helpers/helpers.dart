import 'package:flutter/material.dart';
import 'package:get/get.dart';

class THelperFunctions {
  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showErrorSnackBar(String message) {
    Get.snackbar(
      "Error",
      message,
      isDismissible: true,
      shouldIconPulse: true,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.red),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  static void showSuccessSnackBar(String message) {
    Get.snackbar(
      "Success",
      message,
      isDismissible: true,
      shouldIconPulse: true,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  static void showWarningSnackBar(String message) {
    Get.snackbar(
      "Warning",
      message,
      isDismissible: true,
      shouldIconPulse: true,
      backgroundColor: Colors.yellow.withValues(alpha: 0.1),
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.yellow),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  static void showLoadingOverlay() {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  static void stopLoading() {
    Navigator.pop(Get.overlayContext!);
  }

  static void navigateToScreen(Widget screen) {
    Get.to(() => screen);
  }

  static void navigateToScreenWithReplacement(Widget screen) {
    Get.offAll(() => screen);
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }
}
