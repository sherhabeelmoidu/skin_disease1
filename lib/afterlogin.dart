import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerPage extends StatefulWidget {
  @override
  _ImagePickerPageState createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  XFile? _pickedFile;
  Uint8List? _webImageBytes; // For Web

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _pickedFile = pickedFile;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _pickedFile = null;
      _webImageBytes = null;
    });
  }

  Widget _buildImageWidget() {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Image.memory(_webImageBytes!, fit: BoxFit.cover);
      }
    } else {
      if (_pickedFile != null) {
        return Image.file(io.File(_pickedFile!.path), fit: BoxFit.cover);
      }
    }
    return Icon(Icons.image, size: 100, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('insert your image',style: GoogleFonts.poppins(fontWeight: FontWeight.w800),)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: _buildImageWidget(),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
            SizedBox(height: 20), 
            ElevatedButton(onPressed: _clearImage, child: Text('Clear Image')),
          ],
        ),
      ),
    );
  }
}
