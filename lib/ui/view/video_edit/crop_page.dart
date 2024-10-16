import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:video_editor/video_editor.dart';

class CropPage extends StatelessWidget {
  const CropPage({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Crop Video",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Expanded(
                child: CropGridViewer.edit(
                  controller: controller,
                  rotateCropArea: false,
                ),
              ),
              const SizedBox(height: 15),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  flex: 4,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => controller.preferredCropAspectRatio = controller.preferredCropAspectRatio?.toFraction().inverse().toDouble(),
                              icon: controller.preferredCropAspectRatio != null && controller.preferredCropAspectRatio! < 1
                                  ? const Icon(Icons.panorama_vertical_select_rounded, color: Color(0xff6EA9FF))
                                  : const Icon(Icons.panorama_vertical_rounded),
                            ),
                            IconButton(
                              onPressed: () => controller.preferredCropAspectRatio = controller.preferredCropAspectRatio?.toFraction().inverse().toDouble(),
                              icon: controller.preferredCropAspectRatio != null && controller.preferredCropAspectRatio! > 1
                                  ? const Icon(Icons.panorama_horizontal_select_rounded, color: Color(0xff6EA9FF))
                                  : const Icon(Icons.panorama_horizontal_rounded),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: IconButton(
                                onPressed: () => controller.rotate90Degrees(RotateDirection.left),
                                icon: const Icon(Icons.rotate_left),
                              ),
                            ),
                            _buildCropButton(context, null),
                            _buildCropButton(context, 1.toFraction()),
                            _buildCropButton(context, Fraction.fromString("9/16")),
                            _buildCropButton(context, Fraction.fromString("3/4")),
                            Expanded(
                              child: IconButton(
                                onPressed: () => controller.rotate90Degrees(RotateDirection.right),
                                icon: const Icon(Icons.rotate_right),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xff6EA9FF),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          height: 50, // Adjusted height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Center(
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff6EA9FF)),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () {
                    controller.applyCacheCrop();
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Text(
                      "Done",
                      style: TextStyle(
                        color: const CropGridStyle().selectedBoundariesColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropButton(BuildContext context, Fraction? f) {
    if (controller.preferredCropAspectRatio != null && controller.preferredCropAspectRatio! > 1) {
      f = f?.inverse();
    }
    return Flexible(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: controller.preferredCropAspectRatio == f?.toDouble() ? Colors.grey.shade800 : Colors.transparent,
          foregroundColor: controller.preferredCropAspectRatio == f?.toDouble() ? Colors.white : Colors.black,
          textStyle: Theme.of(context).textTheme.bodySmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: () => controller.preferredCropAspectRatio = f?.toDouble(),
        child: Text(f == null ? 'Free' : '${f.numerator}:${f.denominator}'),
      ),
    );
  }
}
