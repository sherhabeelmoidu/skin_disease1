import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

// Your API Endpoint (Replace with your actual ngrok or server URL)
const String _apiUrl = "https://your-api-endpoint.ngrok-free.app/predict";

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
      // Expected response format: {"disease": "...", "confidence": 0.95}
      return {
        'label': result['disease'] ?? 'Unknown',
        'confidence': (result['confidence'] ?? 0.0).toDouble(),
      };
    } else {
       // Fallback for demo if API is not reachable, but ideally show error
       throw Exception("API Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint('Inference error: $e');
    // For demo/testing, you might want to return mock data if API fails
    // return {'label': 'Chickenpox (Demo)', 'confidence': 0.92};
    rethrow;
  }
}
