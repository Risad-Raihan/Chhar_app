import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Format date to readable string
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  // Calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  // Copy text to clipboard and show snackbar
  static void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Generate a random ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Show a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Format discount percentage
  static String formatDiscount(double percentage) {
    return '${percentage.toInt()}% OFF';
  }
  
  // Get color based on discount percentage
  static Color getDiscountColor(double percentage) {
    if (percentage >= 50) {
      return Colors.red;
    } else if (percentage >= 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  // Get expiry status text and color
  static Map<String, dynamic> getExpiryStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final isExpired = now.isAfter(expiryDate);
    final daysRemaining = daysBetween(now, expiryDate);
    
    if (isExpired) {
      return {
        'text': 'Expired',
        'color': Colors.red,
      };
    } else if (daysRemaining <= 3) {
      return {
        'text': 'Expires soon',
        'color': Colors.orange,
      };
    } else {
      return {
        'text': '$daysRemaining days left',
        'color': Colors.green,
      };
    }
  }
} 