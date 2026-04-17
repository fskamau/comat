import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:comat/core/constants/app_constants.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  static const List<String> _models = [
    'gemini-3.1-flash-lite-preview',
    'gemini-2.5-flash-lite'
  ];

  GeminiService();

  /// Analyzes a marketplace listing image and extracts product details.
  Future<Map<String, dynamic>?> analyzeListing(String imagePath) async {
    final startTime = DateTime.now();
    debugLog('analyzeListing: Started for $imagePath');

    try {
      final File file = File(imagePath);
      if (!await file.exists()) {
        debugLog('analyzeListing: File not found: $imagePath');
        throw Exception("File not found at $imagePath");
      }

      final bytes = await file.readAsBytes();
      debugLog('analyzeListing: Image bytes loaded (${bytes.length} bytes)');

      // AI prompt for data extraction and validation
      final promptText = """
  ROLE: Marketplace Safety & Data Analyst.
  CONTEXT: Analyze item for a specialized community marketplace. 
  
  RULES:
  1. PERMITTED ITEMS: Electronics, books, clothing, household goods, and other typical student/resident items.
  2. FORBIDDEN ITEMS: Vehicles, weapons, prohibited substances, or illegal items.
  
  3. EVALUATION: If the item is NOT permitted, return ONLY this JSON:
     { "error": "Brief reason why the item is not allowed." }

  4. DATA EXTRACTION: If approved, return ONLY this JSON:
  {
    "title": "Clear, professional product name",
    "price": Estimate fair used value in local currency (KSH) as an integer,
    "category": "Must be one of: ${AppConstants.categories.join(', ')}",
    "condition": "Must be one of: ${AppConstants.conditions.join(', ')}",
    "description": "Professional product description under 250 words."
  }
""";

      final content = [
        Content.multi([TextPart(promptText), DataPart('image/jpeg', bytes)]),
      ];
      if (apiKey == null) {
        throw Exception("did you add your api key");
      }

      // Try available models with fallback logic
      for (var modelName in _models) {
        try {
          debugLog('analyzeListing: Attempting with model $modelName');

          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey!,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
          );

          final response = await model.generateContent(content);

          if (response.text == null) {
            debugLog('analyzeListing: $modelName returned empty text');
            continue;
          }

          debugLog('analyzeListing: Successful response from $modelName');
          _logPerformance(modelName, response.usageMetadata, startTime);

          return jsonDecode(response.text!) as Map<String, dynamic>;
        } catch (e) {
          debugLog('analyzeListing: Model $modelName failed: ${e.toString()}');

          if (e.toString().contains('503')) {
            continue; // Fallback to next model on service unavailable
          }

          if (_models.indexOf(modelName) < _models.length - 1) {
            continue; // Try next model
          }
        }
      }

      return {"error": "Service temporarily unavailable. Please try again later."};
    } catch (e) {
      debugLog('analyzeListing: Fatal error: ${e.toString()}');
      return {"error": "An unexpected error occurred. Please try again."};
    }
  }

  /// Logs AI processing performance metrics.
  void _logPerformance(
    String modelName,
    UsageMetadata? usage,
    DateTime startTime,
  ) {
    if (usage == null) return;

    final duration = DateTime.now().difference(startTime);
    final int input = usage.promptTokenCount ?? 0;
    final int output = usage.candidatesTokenCount ?? 0;
    final int total = usage.totalTokenCount ?? 0;

    debugLog('\n--- PERFORMANCE REPORT ---\n'
        'MODEL:    $modelName\n'
        'TOKENS:   In: $input | Out: $output | Total: $total\n'
        'TIME:     ${duration.inMilliseconds}ms\n'
        '--------------------------');
  }

  void debugLog(String message) {
    developer.log(message, name: 'GeminiService');
  }
}
