import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/database_service.dart';
import 'package:ai_voice_to_hand_signs_project/features/auth/screens/login/login.dart';
import 'package:ai_voice_to_hand_signs_project/features/dashboard/dashboard.dart';

class AuthRepositories extends GetxController {
  static AuthRepositories get instance => Get.find();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

  // Get User Email
  late final Rx<User?> firebaseUser;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  // Function to determine relevant screen and redirect accordingly
  void _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAll(() => const LoginScreen());
    } else {
      // Save/update user profile in RTDB on login
      try {
        await Get.find<DatabaseService>().saveUserProfile(user);
      } catch (e) {
        print('Failed to save user profile: $e');
      }
      Get.offAll(() => const DashboardScreen());
    }
  }

  /* ---------------------------- Federated identity & Social Sign In ---------------------------- */
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the pop-up flow
      final GoogleSignInAccount? userAccount = await _googleSignIn
          .authenticate();

      if (userAccount == null) {
        print('Google Sign-In: User cancelled the flow');
        return null; // User cancelled the login
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await userAccount.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw e.message!;
    } catch (e, stackTrace) {
      print('Google Sign-In Error: $e');
      print(stackTrace);
      throw 'Something went wrong with Google Sign-In: $e';
    }
  }

  /* ---------------------------- Email & Password Sign In ---------------------------- */

  /// [EmailAuthentication] - Login
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [EmailAuthentication] - Register
  Future<void> registerWithEmailAndPassword(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /* ---------------------------- Logout ---------------------------- */
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
