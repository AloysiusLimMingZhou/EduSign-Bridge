import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/repositories/auth.repositories.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/colors.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/sizes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.darkBackground,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: TColors.white),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Create Account",
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.apply(color: TColors.white),
              ),
              const SizedBox(height: TSizes.spaceBetweenSections),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First Name
                    TextFormField(
                      controller: firstNameController,
                      style: const TextStyle(color: TColors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.direct, color: TColors.white),
                        labelText: "First Name",
                        labelStyle: TextStyle(color: TColors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBetweenInputFields),
                    // Last Name
                    TextFormField(
                      controller: lastNameController,
                      style: const TextStyle(color: TColors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.direct, color: TColors.white),
                        labelText: "Last Name",
                        labelStyle: TextStyle(color: TColors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBetweenInputFields),
                    // Email
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: TColors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.direct, color: TColors.white),
                        labelText: "Email",
                        labelStyle: TextStyle(color: TColors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBetweenInputFields),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: TColors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Iconsax.password_check,
                          color: TColors.white,
                        ),
                        labelText: "Password",
                        labelStyle: TextStyle(color: TColors.white),
                        suffixIcon: Icon(
                          Iconsax.eye_slash,
                          color: TColors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: TColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBetweenSections),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          side: const BorderSide(color: TColors.primary),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            AuthRepositories.instance
                                .registerWithEmailAndPassword(
                                  firstNameController.text.trim(),
                                  lastNameController.text.trim(),
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );
                          }
                        },
                        child: const Text("Create Account"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
