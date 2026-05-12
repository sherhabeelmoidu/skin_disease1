import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

// Hosted backend base URL (No trailing slash is often safer)
const String _apiUrl = "https://dermasetsnew.onrender.com/";

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

      // Browser-like User-Agent to avoid being blocked by WAFs/Cloudflare
      request.headers['Accept'] = 'application/json';
      request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      request.headers['Connection'] = 'keep-alive';

      // Ensure we always send a 'uid' to get a JSON response from the backend.
      // If no userId is provided, we use a fallback guest ID.
      request.fields['uid'] =
          userId ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';
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
            const Duration(seconds: 120),
            onTimeout: () => throw Exception(
              "Connection timed out. Render instances can take up to two minutes to wake up on the first request. Please try again.",
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
        debugPrint('API Error body: ${response.body}');
        throw Exception("API Error (${response.statusCode}): ${response.body}");
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

      if (e is http.ClientException) {
        debugPrint('ClientException message: ${e.message}');
        debugPrint('ClientException URI: ${e.uri}');
      }
      rethrow;
    }
  }
  throw Exception("Maximum retries reached");
}
