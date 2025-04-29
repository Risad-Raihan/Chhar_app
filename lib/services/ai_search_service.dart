import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import 'dart:async';

class AISearchService {
  static final AISearchService _instance = AISearchService._internal();
  factory AISearchService() => _instance;
  
  late final GenerativeModel _model;
  final ContentfulService _contentfulService = ContentfulService();
  
  AISearchService._internal() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    print('Initializing Gemini model with API key: ${apiKey.substring(0, 10)}...');
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  Future<List<Discount>> searchDiscounts(String query) async {
    int maxRetries = 3;
    int currentTry = 0;
    
    while (currentTry < maxRetries) {
      try {
        print('AI Search attempt ${currentTry + 1}: Processing query "$query"');
        
        // Get all discounts from Contentful
        final allDiscounts = await _contentfulService.getDiscounts();
        print('Retrieved ${allDiscounts.length} discounts to search through');
        
        // Create a simpler prompt for the AI
        final prompt = '''
        User Query: "$query"
        
        Available Discounts:
        ${allDiscounts.asMap().entries.map((entry) => 
          "${entry.key}. ${entry.value.title} - ${entry.value.description ?? 'No description'}"
        ).join('\n')}

        Task: Return ONLY the numbers (indices) of discounts that match the query, separated by commas. Example: "0,3,5"
        If no matches found, return exactly "none".
        ''';

        print('Sending prompt to Gemini API...');
        final content = Content.text(prompt);
        final response = await _model.generateContent([content]);
        final result = response.text;
        print('Received AI response: $result');
        
        if (result == null) {
          print('AI returned null response');
          throw Exception('Invalid response from AI service');
        }

        if (result.toLowerCase().trim() == 'none') {
          print('AI found no matching discounts');
          return [];
        }
        
        // Parse indices and return matching discounts
        final indices = result
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .where((i) => i != null && i < allDiscounts.length)
            .map((i) => i!)
            .toList();
        
        print('Parsed indices from AI response: $indices');
        
        if (indices.isEmpty) {
          print('No valid indices found in AI response');
          return [];
        }

        final matchingDiscounts = indices.map((i) => allDiscounts[i]).toList();
        print('Found ${matchingDiscounts.length} matching discounts');
        return matchingDiscounts;
        
      } catch (e) {
        currentTry++;
        print('AI search attempt $currentTry failed with error: $e');
        
        if (e.toString().contains('overloaded')) {
          if (currentTry < maxRetries) {
            final waitTime = Duration(seconds: 2 * currentTry);
            print('Service overloaded, waiting ${waitTime.inSeconds} seconds before retry...');
            await Future.delayed(waitTime);
            continue;
          }
        }
        
        // If we've exhausted retries or hit a different error, rethrow with a user-friendly message
        throw Exception(
          e.toString().contains('overloaded')
              ? 'AI service is temporarily busy. Please try again in a few moments.'
              : 'Error searching discounts: ${e.toString()}'
        );
      }
    }
    
    throw Exception('Failed to get response after $maxRetries attempts');
  }
} 