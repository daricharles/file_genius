import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_genius/services/error_handler_service.dart';

void main() {
  group('ErrorHandler Widget Tests', () {
    late ErrorHandlerService errorHandler;

    setUp(() {
      errorHandler = ErrorHandlerService();
    });

    testWidgets('should show error snackbar with correct content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorSnackBar(
                          context,
                          message: 'Test error message',
                        ),
                    child: const Text('Show Error'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('should show success snackbar with correct content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showSuccessSnackBar(
                          context,
                          message: 'Operation successful',
                        ),
                    child: const Text('Show Success'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show success snackbar
      await tester.tap(find.text('Show Success'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Operation successful'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show info snackbar with correct content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showInfoSnackBar(
                          context,
                          message: 'Information message',
                        ),
                    child: const Text('Show Info'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show info snackbar
      await tester.tap(find.text('Show Info'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Information message'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('should show error dialog with correct content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorDialog(
                          context,
                          title: 'Error Title',
                          message: 'Error message content',
                        ),
                    child: const Text('Show Dialog'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message content'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('should show error dialog with action button', (
      WidgetTester tester,
    ) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorDialog(
                          context,
                          title: 'Error Title',
                          message: 'Error message content',
                          actionText: 'Retry',
                          onAction: () => actionCalled = true,
                        ),
                    child: const Text('Show Dialog'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown with action button
      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message content'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap the action button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify action was called
      expect(actionCalled, isTrue);
    });

    testWidgets('should dismiss error dialog when OK is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorDialog(
                          context,
                          title: 'Error Title',
                          message: 'Error message content',
                        ),
                    child: const Text('Show Dialog'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Error Title'), findsOneWidget);

      // Tap OK to dismiss
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.text('Error Title'), findsNothing);
    });

    testWidgets('should dismiss snackbar when dismiss button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorSnackBar(
                          context,
                          message: 'Test error message',
                        ),
                    child: const Text('Show Error'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Test error message'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      // Verify snackbar is dismissed
      expect(find.text('Test error message'), findsNothing);
    });

    testWidgets('should handle multiple snackbars correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Column(
                    children: [
                      ElevatedButton(
                        onPressed:
                            () => errorHandler.showErrorSnackBar(
                              context,
                              message: 'First error',
                            ),
                        child: const Text('Show Error 1'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => errorHandler.showErrorSnackBar(
                              context,
                              message: 'Second error',
                            ),
                        child: const Text('Show Error 2'),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );

      // Show first error
      await tester.tap(find.text('Show Error 1'));
      await tester.pump();

      // Verify first error is shown
      expect(find.text('First error'), findsOneWidget);

      // Show second error
      await tester.tap(find.text('Show Error 2'));
      await tester.pump();

      // Verify second error replaces first
      expect(find.text('First error'), findsNothing);
      expect(find.text('Second error'), findsOneWidget);
    });

    testWidgets('should show snackbar with custom duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed:
                        () => errorHandler.showErrorSnackBar(
                          context,
                          message: 'Custom duration error',
                          duration: const Duration(seconds: 10),
                        ),
                    child: const Text('Show Custom Duration'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button to show error snackbar
      await tester.tap(find.text('Show Custom Duration'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Custom duration error'), findsOneWidget);

      // Wait for default duration (4 seconds) - should still be visible
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Custom duration error'), findsOneWidget);

      // Wait for custom duration to expire
      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Custom duration error'), findsNothing);
    });
  });
}


