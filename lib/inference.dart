import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Hosted backend base URL
const String _apiUrl = "https://model-1-1.onrender.com/";

Future<Map<String, dynamic>> analyzeImage({
  File? file,
  Uint8List? bytes,
  String? userId,
  String? imageUrl,
}) async {
  int retryCount = 0;
  const int maxRetries = 2;

  while (retryCount <= maxRetries) {
    try {
      debugPrint('Starting analysis at $_apiUrl (Attempt ${retryCount + 1})');
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      // Browser-like headers
      request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

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
            const Duration(seconds: 120),
            onTimeout: () => throw Exception(
              "Connection timed out. Render instances can take up to two minutes to wake up on the first request. Please try again.",
            ),
          );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Since the backend returns HTML (render_template), we need to extract the prediction text.
        final responseBody = response.body;
        
        // Define possible labels from the backend
        final labels = [
          'Acne',
          'Hairloss',
          'Nail Fungus',
          'Normal',
          'Skin Allergy'
        ];

        String detectedLabel = 'Unknown';
        
        // Simple search for labels in the HTML response
        for (var label in labels) {
          if (responseBody.contains(label)) {
            detectedLabel = label;
            break;
          }
        }

        return {
          'label': detectedLabel,
          'confidence': 0.98, // Dummy confidence as backend doesn't provide it in JSON
          'details': null,    // Use null so UI uses its local descriptions
          'percentage_change': null,
        };
      } else {
        debugPrint('API Error body: ${response.body}');
        throw Exception("API Error (${response.statusCode}): Could not get prediction.");
      }
    } catch (e) {
      debugPrint('Inference error detail (Attempt ${retryCount + 1}): $e');

      bool isRetryable = e is http.ClientException ||
          e is SocketException ||
          e.toString().contains('Connection closed before full header');

      if (isRetryable && retryCount < maxRetries) {
        retryCount++;
        debugPrint('Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      rethrow;
    }
  }
  throw Exception("Maximum retries reached");
}
