import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/repositories/auth.repositories.dart';
import 'package:ai_voice_to_hand_signs_project/util/helpers/helpers.dart';

class LoginController extends GetxController {
  final controller = Get.put(AuthRepositories());
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;

  Future<void> loginWithEmailAndPassword() async {
    try {
      isLoading.value = true;
      if (!loginFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }
      await controller.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );
    } catch (e) {
      THelperFunctions.showErrorSnackBar(e.toString());
    } finally {
      THelperFunctions.stopLoading();
      isLoading.value = false;
    }
  }
}
