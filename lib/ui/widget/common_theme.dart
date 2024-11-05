import 'package:flutter/services.dart';
class ThemeUtils {
  static void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}