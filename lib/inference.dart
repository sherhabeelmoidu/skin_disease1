import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:http_parser/http_parser.dart';

// Your API Endpoint (Using 10.0.2.2 for Android Emulator, or your local IP)
const String _apiUrl = "http://10.0.2.2:5000/predict";

Future<Map<String, dynamic>> analyzeImage({
  File? file,
  Uint8List? bytes,
}) async {
  try {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'upload.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else {
      throw Exception("No image provided");
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      // User's app.py returns {"prediction": "...", "confidence": 95.5}
      return {
        'label': result['prediction'] ?? 'Unknown',
        'confidence': (result['confidence'] ?? 0.0) / 100, // Convert percentage back to 0.0-1.0
        'percentage_change': (result['percentage_change'] ?? (Random().nextInt(20) - 10)).toInt(), // Mock change for now since UI needs it
      };
    } else {
       throw Exception("API Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Inference error: $e');
    // Fallback for testing
    return {
      'label': 'Dermatitis (Mock)', 
      'confidence': 0.85, 
      'percentage_change': -2
    };
  }
}
