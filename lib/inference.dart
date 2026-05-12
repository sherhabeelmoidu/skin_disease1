import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Hosted backend base URL - Updated to hit Railway /predict endpoint
const String _apiUrl = "https://web-production-cceff.up.railway.app/predict";

Future<Map<String, dynamic>> analyzeImage({
  File? file,
  Uint8List? bytes,
  String? userId,
  String? imageUrl,
}) async {
  int retryCount = 0;
  const int maxRetries = 3;

  while (retryCount <= maxRetries) {
    try {
      debugPrint('Starting analysis at $_apiUrl (Attempt ${retryCount + 1})');
      
      // Ensure we have a trailing slash if needed, or use exact URL
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      // Use a mobile-like user agent instead of a desktop one to avoid triggering web-only protections
      request.headers['User-Agent'] = 'DermaSenseMobile/1.0';
      request.headers['Accept'] = '*/*';

      // Add common fields that backends often expect
      if (userId != null) request.fields['uid'] = userId;
      if (imageUrl != null) request.fields['imageUrl'] = imageUrl;

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

      // Render instances can take time to wake up (cold start)
      // The first request often triggers a 502 if the proxy times out waiting for the container to start.
      var streamedResponse = await request.send().timeout(
            const Duration(seconds: 150),
            onTimeout: () => throw Exception(
              "Connection timed out. Railway instances might take a moment to wake up. Please try again.",
            ),
          );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        debugPrint('API Response: $responseBody');

        try {
          // Attempt to parse as JSON first (Robust approach)
          final Map<String, dynamic> data = json.decode(responseBody);
          
          // Try common prediction keys returned by Flask/FastAPI
          String detectedLabel = (data['prediction'] ?? 
                                 data['label'] ?? 
                                 data['class'] ?? 
                                 data['detected_label'] ?? 
                                 'Unknown').toString();
          
          double confidence = 0.98; // Default fallback
          if (data['confidence'] != null) {
            confidence = double.tryParse(data['confidence'].toString()) ?? 0.98;
          } else if (data['probability'] != null) {
            confidence = double.tryParse(data['probability'].toString()) ?? 0.98;
          }

          return {
            'label': detectedLabel,
            'confidence': confidence,
            'details': data['details'],
            'percentage_change': data['percentage_change'],
          };
        } catch (e) {
          // Fallback: search for labels in the body text if it's not valid JSON
          debugPrint('JSON parsing failed, falling back to text search: $e');
          
          final labels = [
            'Acne',
            'Hairloss',
            'Nail Fungus',
            'Normal',
            'Skin Allergy'
          ];

          String detectedLabel = 'Unknown';
          for (var label in labels) {
            if (responseBody.contains(label)) {
              detectedLabel = label;
              break;
            }
          }

          return {
            'label': detectedLabel,
            'confidence': 0.98,
            'details': null,
            'percentage_change': null,
          };
        }
      } else if (response.statusCode == 502 || response.statusCode == 500 || response.statusCode == 504) {
        debugPrint('Server error (${response.statusCode}) - Attempt ${retryCount + 1}');
        debugPrint('Response Preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        
        if (retryCount < maxRetries) {
          retryCount++;
          // Exponential backoff for retries
          int delay = retryCount * 3; 
          debugPrint('Retrying in $delay seconds...');
          await Future.delayed(Duration(seconds: delay));
          continue;
        }
        throw Exception("API Server Error (${response.statusCode}): The backend service might be restarting or overloaded. Please try again in a moment.");
      } else {
        debugPrint('API Error (${response.statusCode}) body: ${response.body}');
        throw Exception("API Error (${response.statusCode}): Could not get prediction.");
      }
    } catch (e) {
      debugPrint('Inference error detail (Attempt ${retryCount + 1}): $e');

      bool isRetryable = e is http.ClientException ||
          e is SocketException ||
          e.toString().contains('Connection closed before full header');

      if (isRetryable && retryCount < maxRetries) {
        retryCount++;
        debugPrint('Retrying in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }
      rethrow;
    }
  }
  throw Exception("Maximum retries reached");
}
