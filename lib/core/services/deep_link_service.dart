// services/deep_link_service.dart
import 'package:uni_links3/uni_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import '../../features/auth/data/repositories/auth_repository_impl.dart';

class DeepLinkService {
  final AuthRepositoryImpl authRepository;
  bool _isInitialized = false;

  DeepLinkService(this.authRepository);

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize deep links and optionally pass app's [navigatorKey] so we can
  /// navigate to verification/result pages when a deep link arrives.
  void initializeDeepLinks([GlobalKey<NavigatorState>? navigatorKey]) {
    _navigatorKey = navigatorKey;
    if (_isInitialized) {
      developer.log('Deep links already initialized');
      return;
    }

    // Skip deep links on unsupported platforms — uni_links supports
    // Android / iOS (and some Apple platforms). On desktop (Windows/Linux)
    // uni_links may not be implemented and throws MissingPluginException.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      developer.log('Deep links not initialized: running on Web.');
      _isInitialized = true;
      return;
    }

    // Call uni_links safely. Plugins can be missing on some platforms or
    // this method might run before the native platform implementation has
    // registered; catch MissingPluginException gracefully.
    try {
      // Handle initial link when app is launched
      getInitialLink().then(_handleDeepLink).catchError((err) {
        developer.log('getInitialLink error: $err');
      });

      // Handle links when app is in foreground
      linkStream.listen(_handleDeepLink, onError: (err) {
        developer.log('linkStream error: $err');
      });
    } on MissingPluginException catch (e) {
      developer.log('uni_links plugin not available on this platform: $e');
    } catch (e) {
      developer.log('Unexpected error initializing deep links: $e');
    }

    _isInitialized = true;
    developer.log('Deep links initialized');
  }

  /// Re-initializes deep link listeners, useful after registration when the user
  /// might receive a verification email with a deep link
  void reInitializeDeepLinks() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    // Attempt to read any pending initial link; if plugin missing we just
    // log and gracefully return.
    try {
      getInitialLink().then((link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      }).catchError((err) {
        developer.log('reInitialize getInitialLink error: $err');
      });
    } on MissingPluginException catch (e) {
      developer.log('uni_links plugin not available for re-initialize: $e');
    } catch (e) {
      developer.log('Unexpected error in reInitializeDeepLinks: $e');
    }

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
      // navigate to verification UI to give user feedback
      try {
        _navigatorKey?.currentState?.pushNamed(
          '/verify-email',
          arguments: {
            'status': 'success',
            'message': 'Email verified successfully! You can close this window.'
          },
        );
      } catch (e) {
        developer.log('Failed to navigate to verification page: $e');
      }
      // You might want to use a state manager or callback here
      // to notify the UI about successful verification
    } catch (e) {
      developer.log('Email verification failed: $e', error: e);
      // Handle error - navigate to verification page with failure message
      try {
        _navigatorKey?.currentState?.pushNamed(
          '/verify-email',
          arguments: {
            'status': 'failed',
            'message': 'Failed to verify email: ${e.toString()}'
          },
        );
      } catch (e2) {
        developer.log('Failed to navigate to verification page on error: $e2');
      }
      rethrow;
    }
  }
}
