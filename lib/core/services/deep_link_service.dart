// services/deep_link_service.dart
import 'package:uni_links/uni_links.dart';
import 'dart:developer' as developer;
import '../../features/auth/data/repositories/auth_repository_impl.dart';

class DeepLinkService {
  final AuthRepositoryImpl authRepository;
  bool _isInitialized = false;

  DeepLinkService(this.authRepository);

  void initializeDeepLinks() {
    if (_isInitialized) {
      developer.log('Deep links already initialized');
      return;
    }

    // Handle initial link when app is launched
    getInitialLink().then(_handleDeepLink);

    // Handle links when app is in foreground
    linkStream.listen(_handleDeepLink);

    _isInitialized = true;
    developer.log('Deep links initialized');
  }

  /// Re-initializes deep link listeners, useful after registration when the user
  /// might receive a verification email with a deep link
  void reInitializeDeepLinks() {
    // Check for any pending deep link that might have been received
    getInitialLink().then((link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });

    developer
        .log('Deep links re-initialized for post-registration verification');
  }

  void _handleDeepLink(String? link) {
    if (link == null) {
      developer.log('Received null deep link');
      return;
    }

    final uri = Uri.parse(link);
    developer.log('Handling deep link: $uri');

    // Check if this is an email verification link
    if (uri.path.contains('/verify')) {
      final userId = uri.queryParameters['userId'];
      final secret = uri.queryParameters['secret'];

      developer.log(
          'Detected verification link - userId: $userId, secret: ${secret?.substring(0, 10)}...');

      if (userId != null && secret != null) {
        _handleEmailVerification(userId, secret);
      } else {
        developer.log('Missing userId or secret in verification link');
      }
    } else {
      developer.log('Deep link does not match any known patterns: ${uri.path}');
    }
  }

  Future<void> _handleEmailVerification(String userId, String secret) async {
    try {
      developer.log('Starting email verification for userId: $userId');
      await authRepository.confirmVerification(userId, secret);
      developer.log('Email verification completed successfully');
      // You might want to use a state manager or callback here
      // to notify the UI about successful verification
    } catch (e) {
      developer.log('Email verification failed: $e', error: e);
      // Handle error - maybe show a snackbar or dialog
      rethrow;
    }
  }
}
