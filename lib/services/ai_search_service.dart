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

        // First, try to match by category
        final lowerQuery = query.toLowerCase();
        final List<Discount> categoryMatches = allDiscounts.where((discount) {
          final category = discount.category.toLowerCase();
          final title = discount.title.toLowerCase();
          final store = discount.store.toLowerCase();
          final description = (discount.description ?? '').toLowerCase();

          // Check for direct matches in various fields
          return category.contains(lowerQuery) ||
                 title.contains(lowerQuery) ||
                 store.contains(lowerQuery) ||
                 description.contains(lowerQuery) ||
                 _matchesCategory(lowerQuery, category, title, description);
        }).toList();

        // If we found direct matches, use AI to rank and filter them
        if (categoryMatches.isNotEmpty) {
          final rankingPrompt = '''Rank these discounts by relevance to the query "$query":

Available Discounts:
${categoryMatches.asMap().entries.map((entry) => """${entry.key}. Title: ${entry.value.title}
   Category: ${entry.value.category}
   Store: ${entry.value.store}
   Description: ${entry.value.description ?? 'No description'}
""").join('\n')}

Return ONLY the numbers of relevant discounts in order of relevance, separated by commas (e.g., "2,0,1").
If none are relevant, return "none".''';

          print('Sending ranking prompt to Gemini API...');
          final content = Content.text(rankingPrompt);
          final response = await _model.generateContent([content]);
          final result = response.text;
          print('Received AI ranking response: $result');

          if (result == null || result.toLowerCase().trim() == 'none') {
            return categoryMatches; // Return all category matches if AI can't rank
          }

          // Parse indices and return ranked matches
          final indices = result
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .where((i) => i != null && i < categoryMatches.length)
              .map((i) => i!)
              .toList();

          return indices.map((i) => categoryMatches[i]).toList();
        }

        // If no category matches, fall back to pure AI search
        final prompt = '''Analyze these discounts and find matches for the query "$query":

Available Discounts:
${allDiscounts.asMap().entries.map((entry) => """${entry.key}. Title: ${entry.value.title}
   Category: ${entry.value.category}
   Store: ${entry.value.store}
   Description: ${entry.value.description ?? 'No description'}
""").join('\n')}

Instructions:
- Return ONLY the numbers of matching discounts (e.g., "0,3,5")
- Consider similar terms (e.g., "electronics" matches "laptop", "computer")
- Consider store names and categories
- If no matches found, return exactly "none"''';

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
        print('Error details: ${e.toString()}');
        
        if (e.toString().contains('overloaded') || e.toString().contains('not found')) {
          if (currentTry < maxRetries) {
            final waitTime = Duration(seconds: 2 * currentTry);
            print('Service issue, waiting ${waitTime.inSeconds} seconds before retry...');
            await Future.delayed(waitTime);
            continue;
          }
        }
        
        throw Exception(
          e.toString().contains('overloaded')
              ? 'AI service is temporarily busy. Please try again in a few moments.'
              : e.toString().contains('not found')
                  ? 'AI model configuration error. Please check your API setup.'
                  : 'Error searching discounts: ${e.toString()}'
        );
      }
    }
    
    throw Exception('Failed to get response after $maxRetries attempts');
  }

  bool _matchesCategory(String query, String category, String title, String description) {
    // Define category synonyms and related terms
    final categoryMatches = {
      'food': ['restaurant', 'dining', 'meal', 'cuisine', 'eat'],
      'electronics': ['laptop', 'computer', 'tech', 'digital', 'device', 'gadget'],
      'travel': ['hotel', 'flight', 'trip', 'tour', 'vacation', 'holiday'],
      'fashion': ['clothing', 'apparel', 'wear', 'dress', 'outfit'],
      'beauty': ['cosmetics', 'makeup', 'skincare', 'salon'],
    };

    // Check if query matches any related terms
    for (final entry in categoryMatches.entries) {
      if (entry.key.contains(query) || entry.value.any((term) => query.contains(term))) {
        // If category matches, check if discount is actually related
        return category.contains(entry.key) ||
               title.contains(entry.key) ||
               description.contains(entry.key) ||
               entry.value.any((term) => 
                 category.contains(term) || 
                 title.contains(term) || 
                 description.contains(term)
               );
      }
    }
    return false;
  }
} 