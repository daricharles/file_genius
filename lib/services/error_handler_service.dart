import 'package:flutter/material.dart';

/// Service for handling errors and providing user-friendly error messages
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Get user-friendly error message
  String getUserFriendlyMessage(dynamic error, {String? context}) {
    // Normalize to string for robust matching
    final errorString = error.toString().toLowerCase();

    // Handle common string-form messages first
    final stringMatch = _getMessageFromString(errorString, context);
    if (stringMatch != null) return stringMatch;

    // Firebase Auth errors
    if (errorString.contains('user-not-found')) {
      return 'Account not found. Please check your email or create a new account.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    if (errorString.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }

    // File operation errors
    if (errorString.contains('permission-denied')) {
      return 'Permission denied. Please check your account access.';
    }
    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return 'File or folder not found. It may have been deleted.';
    }
    if (errorString.contains('already-exists') ||
        errorString.contains('already exists')) {
      return 'A file with this name already exists. Please choose a different name.';
    }
    if (errorString.contains('quota-exceeded')) {
      return 'Storage quota exceeded. Please delete some files or upgrade your plan.';
    }

    // AI service errors
    if (errorString.contains('quota exceeded')) {
      return 'AI service quota exceeded. Please try again later.';
    }
    if (errorString.contains('invalid api key')) {
      return 'AI service configuration error. Please contact support.';
    }
    if (errorString.contains('rate limit')) {
      return 'Too many AI requests. Please wait a moment before trying again.';
    }

    // Generic errors
    if (errorString.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    }
    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorString.contains('server')) {
      return 'Server error. Please try again later.';
    }

    // Default message
    return _getDefaultMessage(context);
  }

  /// Get error message from string
  String? _getMessageFromString(String error, String? context) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('failed to upload')) {
      return 'File upload failed. Please check your internet connection and try again.';
    }
    if (lowerError.contains('failed to delete')) {
      return 'Failed to delete item. Please try again.';
    }
    if (lowerError.contains('failed to create')) {
      return 'Failed to create item. Please try again.';
    }
    if (lowerError.contains('failed to load')) {
      return 'Failed to load data. Please refresh and try again.';
    }
    if (lowerError.contains('failed to save')) {
      return 'Failed to save changes. Please try again.';
    }

    return null; // Let caller decide default
  }

  /// Get default error message
  String _getDefaultMessage(String? context) {
    if (context != null) {
      return 'An error occurred while $context. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Get error icon
  IconData getErrorIcon(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('timeout')) {
      return Icons.wifi_off;
    }
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return Icons.lock;
    }
    if (errorString.contains('quota') || errorString.contains('exceeded')) {
      return Icons.storage;
    }
    if (errorString.contains('not-found') ||
        errorString.contains('not found')) {
      return Icons.search_off;
    }

    return Icons.error_outline;
  }

  /// Get error color
  Color getErrorColor(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('quota') || errorString.contains('exceeded')) {
      return Colors.orange;
    }
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return Colors.red;
    }
    if (errorString.contains('network') || errorString.contains('timeout')) {
      return Colors.blue;
    }

    return Colors.red;
  }

  /// Show error dialog
  Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            if (actionText != null && onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
                child: Text(actionText),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show info snackbar
  void showInfoSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
      ),
    );
  }
}
