import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

showSnackBar({required BuildContext context,required bool isError,required String message}) => SchedulerBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
      SnackBar(
        backgroundColor: isError == true ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.startToEnd,
        elevation: 30,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isError == true ? Colors.red : Colors.green),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  },
);
