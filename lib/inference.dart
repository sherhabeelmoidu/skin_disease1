import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

// Replace this with your laptop's IP address (e.g., "192.168.1.10")
// You can find your IP by running 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux)
const String _laptopIp = "192.168.1.38"; // User's laptop IP address
const String _apiUrl = "http://$_laptopIp:5000/predict";

Future<Map<String, dynamic>> analyzeImage({
  File? file,
  Uint8List? bytes,
  String? userId,
  String? imageUrl,
}) async {
  try {
    debugPrint('Starting analysis at $_apiUrl');
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

    if (userId != null) {
      request.fields['uid'] = userId;
    }
    if (imageUrl != null) {
      request.fields['image_url'] = imageUrl;
    }

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      throw Exception("No image provided");
    }

    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        "Connection timed out. Check if your backend is running at $_apiUrl",
      ),
    );

    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return {
        'label': result['prediction'] ?? 'Unknown',
        'confidence': ((result['confidence'] ?? 0.0) as num).toDouble() / 100,
        'details': result['details'], // Capture backend-provided details
        'percentage_change': result['percentage_change'] != null
            ? (result['percentage_change'] as num).toInt()
            : null,
      };
    } else if (response.statusCode == 400) {
      String errorMessage = "Bad Request";
      try {
        final errorJson = json.decode(response.body);
        errorMessage = errorJson['error'] ?? response.body;
      } catch (_) {
        errorMessage = response.body;
      }
      throw Exception(errorMessage);
    } else {
      throw Exception("API Error (${response.statusCode}): ${response.body}");
    }
  } catch (e) {
    debugPrint('Inference error: $e');
    // Re-throw so the UI can handle it and show a snackbar
    rethrow;
  }
}
