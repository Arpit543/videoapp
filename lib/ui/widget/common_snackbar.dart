import 'package:flutter/material.dart';

showSnackBar({required BuildContext context,bool isError = false,required String message}) {
  ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
    SnackBar(
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isError ? Colors.red : Colors.green),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

class ColoredTabBar extends Container implements PreferredSizeWidget {
  ColoredTabBar({super.key, required this.colors, required this.tabBar});

  final Color colors;
  final TabBar tabBar;

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => Container(
    color: colors,
    child: tabBar,
  );
}
