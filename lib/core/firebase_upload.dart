import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseUpload extends StatefulWidget {
  const FirebaseUpload({super.key});

  Future<void> uploadFileInStorage(
      {required File file,
      required String type,
      required BuildContext context}) async {
    String fileName = file.toString().split("/").last;
    Reference storageRef =
        FirebaseStorage.instance.ref().child('$type/$fileName');

    try {
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File Uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Upload')),
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
