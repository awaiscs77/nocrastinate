import 'package:home_widget/home_widget.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../AppData/Quotes/QuotesData.dart';

class WidgetManager {
  static const String _lastQuoteDateKey = 'last_quote_date';
  static const String _currentQuoteKey = 'current_quote';
  static const String _currentCategoryKey = 'current_category';

  // IMPORTANT: Replace with your actual App Group ID
  static const String appGroupId = 'group.nocrastinate.app';

  static bool _isInitialized = false;

  /// Initialize the home_widget package with App Group ID
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await HomeWidget.setAppGroupId(appGroupId);
      _isInitialized = true;
    }
  }

  /// Initialize widget with initial data
  static Future<void> initializeWidget() async {
    await _ensureInitialized();
    await updateWidget();
  }

  /// Get a random quote from a random category
  static Map<String, String> getRandomQuote() {
    final random = Random();

    // List of all quote categories
    final categories = [
      {'name': 'Success', 'quotes': QuotesData.successQuotes},
      {'name': 'Leadership', 'quotes': QuotesData.leadershipQuotes},
      {'name': 'Business', 'quotes': QuotesData.businessMoneyQuotes},
      {'name': 'Love', 'quotes': QuotesData.loveQuotes},
      {'name': 'Family', 'quotes': QuotesData.familyQuotes},
      {'name': 'Breakup', 'quotes': QuotesData.breakupQuotes},
      {'name': 'Single Life', 'quotes': QuotesData.beingSingleQuotes},
      {'name': 'Stoicism', 'quotes': QuotesData.stoicismQuotes},
      {'name': 'Buddhism', 'quotes': QuotesData.buddhismQuotes},
      {'name': 'Self-Love', 'quotes': QuotesData.selfLoveQuotes},
      {'name': 'Positive Thinking', 'quotes': QuotesData.positiveThinkingQuotes},
      {'name': 'Gratitude', 'quotes': QuotesData.gratitudeQuotes},
      {'name': 'Be Yourself', 'quotes': QuotesData.beYourselfQuotes},
      {'name': 'Uncertainty', 'quotes': QuotesData.uncertaintyQuotes},
      {'name': 'Resilience', 'quotes': QuotesData.resilienceQuotes},
      {'name': 'Fear', 'quotes': QuotesData.fearQuotes},
      {'name': 'Change', 'quotes': QuotesData.changeQuotes},
      {'name': 'Loneliness', 'quotes': QuotesData.lonelinessQuotes},
      {'name': 'Habits', 'quotes': QuotesData.habitQuotes},
      {'name': 'Fitness', 'quotes': QuotesData.fitnessQuotes},
    ];

    // Select random category
    final category = categories[random.nextInt(categories.length)];
    final quotes = category['quotes'] as List<String>;

    // Select random quote from category
    final quote = quotes[random.nextInt(quotes.length)];

    return {
      'quote': quote,
      'category': category['name'] as String,
    };
  }

  /// Check if we need a new quote (once per day)
  static Future<bool> shouldUpdateQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastQuoteDateKey);
    final today = DateTime.now().toString().split(' ')[0];

    return lastDate != today;
  }

  /// Update the widget with daily quote
  static Future<void> updateWidget() async {
    try {
      await _ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      String quote;
      String category;

      // Check if we need a new quote
      if (await shouldUpdateQuote()) {
        // Get new random quote
        final quoteData = getRandomQuote();
        quote = quoteData['quote']!;
        category = quoteData['category']!;

        // Save to SharedPreferences
        final today = DateTime.now().toString().split(' ')[0];
        await prefs.setString(_lastQuoteDateKey, today);
        await prefs.setString(_currentQuoteKey, quote);
        await prefs.setString(_currentCategoryKey, category);
      } else {
        // Use existing quote
        quote = prefs.getString(_currentQuoteKey) ??
            'Success is not final, failure is not fatal: It is the courage to continue that counts. – Winston Churchill';
        category = prefs.getString(_currentCategoryKey) ?? 'Success';
      }

      // Parse quote to separate text and author
      final parts = quote.split(' – ');
      final quoteText = parts[0].replaceAll('"', '');
      final author = parts.length > 1 ? parts[1] : 'Unknown';

      // Update widget data
      await HomeWidget.saveWidgetData<String>('quote_text', quoteText);
      await HomeWidget.saveWidgetData<String>('quote_author', author);
      await HomeWidget.saveWidgetData<String>('quote_category', category);

      // Update the widget UI
      await HomeWidget.updateWidget(
        name: 'DailyQuoteWidget',
        iOSName: 'DailyQuoteWidget',
      );

      print('Widget updated successfully: $category - $quoteText');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Force refresh widget with new quote
  static Future<void> refreshQuote() async {
    await _ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastQuoteDateKey); // Force new quote
    await updateWidget();
  }

  /// Get current quote from SharedPreferences
  static Future<Map<String, String>> getCurrentQuote() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'quote': prefs.getString(_currentQuoteKey) ??
          'Success is not final, failure is not fatal: It is the courage to continue that counts. – Winston Churchill',
      'category': prefs.getString(_currentCategoryKey) ?? 'Success',
    };
  }
}

// Background callback for widget updates (iOS)
@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  // Set App Group ID first
  await HomeWidget.setAppGroupId(WidgetManager.appGroupId);

  if (uri?.host == 'updatewidget') {
    await WidgetManager.updateWidget();
  }
}