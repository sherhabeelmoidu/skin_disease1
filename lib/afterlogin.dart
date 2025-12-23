import 'package:flutter/material.dart';
import 'package:skin_disease1/camera_gallery_page.dart';

/// After login page — now forwards to the combined Camera + Gallery page.
class ImagePickerPage extends StatelessWidget {
  const ImagePickerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CameraGalleryPage();
  }
}
