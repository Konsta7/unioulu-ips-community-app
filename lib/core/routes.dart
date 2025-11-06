import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/email_verification_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/verify-email':
        return MaterialPageRoute(builder: (_) => const EmailVerificationPage());
      // Add other routes here
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
