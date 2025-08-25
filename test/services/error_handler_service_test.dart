import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:file_genius/services/error_handler_service.dart';

void main() {
  group('ErrorHandlerService', () {
    late ErrorHandlerService errorHandler;

    setUp(() {
      errorHandler = ErrorHandlerService();
    });

    group('getUserFriendlyMessage', () {
      test('should return user-friendly message for Firebase Auth errors', () {
        final error = 'user-not-found';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Account not found'));
        expect(message, contains('check your email'));
      });

      test('should return user-friendly message for wrong password', () {
        final error = 'wrong-password';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Incorrect password'));
        expect(message, contains('try again'));
      });

      test('should return user-friendly message for email already in use', () {
        final error = 'email-already-in-use';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('already exists'));
        expect(message, contains('sign in instead'));
      });

      test('should return user-friendly message for weak password', () {
        final error = 'weak-password';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('too weak'));
        expect(message, contains('stronger password'));
      });

      test('should return user-friendly message for invalid email', () {
        final error = 'invalid-email';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('valid email address'));
      });

      test('should return user-friendly message for too many requests', () {
        final error = 'too-many-requests';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Too many failed attempts'));
        expect(message, contains('try again later'));
      });

      test('should return user-friendly message for network errors', () {
        final error = 'network-request-failed';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Network error'));
        expect(message, contains('internet connection'));
      });
    });

    group('File operation errors', () {
      test('should return user-friendly message for permission denied', () {
        final error = 'permission-denied';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Permission denied'));
        expect(message, contains('account access'));
      });

      test('should return user-friendly message for not found', () {
        final error = 'not-found';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('not found'));
        expect(message, contains('deleted'));
      });

      test('should return user-friendly message for already exists', () {
        final error = 'already-exists';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('already exists'));
        expect(message, contains('different name'));
      });

      test('should return user-friendly message for quota exceeded', () {
        final error = 'quota-exceeded';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Storage quota exceeded'));
        expect(message, contains('upgrade your plan'));
      });
    });

    group('AI service errors', () {
      test('should return user-friendly message for quota exceeded', () {
        final error = 'quota exceeded';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('quota exceeded'));
        expect(message, contains('try again later'));
      });

      test('should return user-friendly message for invalid API key', () {
        final error = 'invalid api key';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('configuration error'));
        expect(message, contains('contact support'));
      });

      test('should return user-friendly message for rate limit', () {
        final error = 'rate limit';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Too many AI requests'));
        expect(message, contains('wait a moment'));
      });
    });

    group('Generic errors', () {
      test('should return user-friendly message for timeout', () {
        final error = 'timeout';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('timed out'));
        expect(message, contains('try again'));
      });

      test('should return user-friendly message for network errors', () {
        final error = 'network';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Network error'));
        expect(message, contains('internet connection'));
      });

      test('should return user-friendly message for server errors', () {
        final error = 'server';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Server error'));
        expect(message, contains('try again later'));
      });
    });

    group('String error messages', () {
      test('should return user-friendly message for upload failure', () {
        final error = 'Failed to upload file.pdf';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('upload failed'));
        expect(message, contains('internet connection'));
      });

      test('should return user-friendly message for delete failure', () {
        final error = 'Failed to delete item';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Failed to delete'));
        expect(message, contains('try again'));
      });

      test('should return user-friendly message for create failure', () {
        final error = 'Failed to create folder';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Failed to create'));
        expect(message, contains('try again'));
      });

      test('should return user-friendly message for load failure', () {
        final error = 'Failed to load data';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Failed to load'));
        expect(message, contains('refresh'));
      });

      test('should return user-friendly message for save failure', () {
        final error = 'Failed to save changes';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, contains('Failed to save'));
        expect(message, contains('try again'));
      });
    });

    group('Default messages', () {
      test('should return default message for unknown error', () {
        final error = 'unknown-error-type';
        final message = errorHandler.getUserFriendlyMessage(error);

        expect(message, 'Something went wrong. Please try again.');
      });

      test('should return contextual default message', () {
        final error = 'unknown-error';
        final context = 'uploading files';
        final message = errorHandler.getUserFriendlyMessage(
          error,
          context: context,
        );

        expect(
          message,
          'An error occurred while uploading files. Please try again.',
        );
      });
    });

    group('Error icons', () {
      test('should return wifi icon for network errors', () {
        final error = 'network error';
        final icon = errorHandler.getErrorIcon(error);

        expect(icon, Icons.wifi_off);
      });

      test('should return lock icon for permission errors', () {
        final error = 'permission denied';
        final icon = errorHandler.getErrorIcon(error);

        expect(icon, Icons.lock);
      });

      test('should return storage icon for quota errors', () {
        final error = 'quota exceeded';
        final icon = errorHandler.getErrorIcon(error);

        expect(icon, Icons.storage);
      });

      test('should return search icon for not found errors', () {
        final error = 'not found';
        final icon = errorHandler.getErrorIcon(error);

        expect(icon, Icons.search_off);
      });

      test('should return error icon for unknown errors', () {
        final error = 'unknown error';
        final icon = errorHandler.getErrorIcon(error);

        expect(icon, Icons.error_outline);
      });
    });

    group('Error colors', () {
      test('should return orange for quota errors', () {
        final error = 'quota exceeded';
        final color = errorHandler.getErrorColor(error);

        expect(color, Colors.orange);
      });

      test('should return red for permission errors', () {
        final error = 'permission denied';
        final color = errorHandler.getErrorColor(error);

        expect(color, Colors.red);
      });

      test('should return blue for network errors', () {
        final error = 'network timeout';
        final color = errorHandler.getErrorColor(error);

        expect(color, Colors.blue);
      });

      test('should return red for unknown errors', () {
        final error = 'unknown error';
        final color = errorHandler.getErrorColor(error);

        expect(color, Colors.red);
      });
    });
  });
}


