import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:ai_voice_to_hand_signs_project/common/styles/spacing_styles.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/repositories/auth.repositories.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/colors.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/image_strings.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/sizes.dart';
import 'package:ai_voice_to_hand_signs_project/util/helpers/helpers.dart';
import 'package:get/get.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/screens/signup/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              // Logo, Title, Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Image(
                      height: 150,
                      image: AssetImage(
                        dark ? TImages.lightAppLogo : TImages.darkAppLogo,
                      ),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBetweenItems),
                  Text(
                    "Welcome to our app",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    "Login to your account",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // Form
              Form(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: TSizes.spaceBetweenSections,
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController, // Added controller
                        style: const TextStyle(
                          color: TColors.white,
                        ), // Theme update
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email, color: TColors.white),
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
                      TextFormField(
                        controller: passwordController, // Added controller
                        obscureText: true,
                        style: const TextStyle(color: TColors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: TColors.white),
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
                      const SizedBox(
                        height: TSizes.spaceBetweenInputFields / 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                checkColor: Colors.white,
                                fillColor: WidgetStatePropertyAll(
                                  TColors.primary,
                                ),
                                value: true,
                                onChanged: (value) {},
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(color: TColors.white),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: TColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBetweenSections),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            foregroundColor: TColors.white,
                          ),
                          onPressed: () {
                            AuthRepositories.instance.loginWithEmailAndPassword(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          },
                          child: const Text("Login"),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBetweenItems),
                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          // Changed to Outlined for style
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: TColors.grey),
                          ),
                          onPressed: () {
                            Get.to(() => const SignupScreen());
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(color: TColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Divider(
                      color: dark ? TColors.darkGrey : TColors.grey,
                      thickness: 0.5,
                      indent: 60,
                      endIndent: 5,
                    ),
                  ),
                  Text(
                    "Or Sign in with",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Flexible(
                    child: Divider(
                      color: dark ? TColors.darkGrey : TColors.grey,
                      thickness: 0.5,
                      indent: 5,
                      endIndent: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBetweenItems),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: TColors.grey),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Get.put(AuthRepositories());
                        AuthRepositories.instance.signInWithGoogle();
                      },
                      icon: const Image(
                        image: AssetImage(TImages.google),
                        width: TSizes.iconMd,
                        height: TSizes.iconMd,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
