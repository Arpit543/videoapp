import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class ThemeUtils {
  static void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        systemNavigationBarColor: color,
        systemNavigationBarDividerColor: Colors.blueGrey,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: true,
        systemNavigationBarContrastEnforced: true,
      ),
    );
  }
}