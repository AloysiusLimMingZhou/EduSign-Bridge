import 'package:flutter/material.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/appbar.theme.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/bottomSheet.theme.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/elevatedButton.theme.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/outlineButton.theme.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/textField.theme.dart';
import 'package:ai_voice_to_hand_signs_project/util/themes/custom_theme/text.theme.dart';

class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    textTheme: TTextTheme.lightTextTheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    textTheme: TTextTheme.darkTextTheme,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
  );
}
