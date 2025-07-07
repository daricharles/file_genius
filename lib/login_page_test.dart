// Dart
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:file_genius/login_page.dart';
import 'package:file_genius/signup_page.dart';

void main() {
  testWidgets('LoginPage renders all fields and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage()),
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.text("Don’t have an account? "), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('Form validation shows errors for empty fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Form validation shows error for invalid email', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.enterText(find.byType(TextFormField).at(0), 'invalidemail');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('Form validation shows error for short password', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Tapping Sign up navigates to SignupPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(),
        routes: {
          '/signup': (context) => const SignupPage(),
        },
      ),
    );
    await tester.tap(find.text('Sign up').last);
    await tester.pumpAndSettle();
    expect(find.byType(SignupPage), findsOneWidget);
  });

  testWidgets('Forgot Password dialog appears', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Enter your email to receive a password reset link.'), findsOneWidget);
  });

  testWidgets('Google sign-in button is present', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}