import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository_impl.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isVerifying = true;
  String _message = 'Verifying your email...';

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      // If navigated here via Navigator arguments (e.g. deep link service), use them
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final status = args['status'] as String?;
        final message = args['message'] as String?;

        setState(() {
          _isVerifying = false;
          if (status == 'success') {
            _message = message ??
                'Email verified successfully! You can close this window.';
          } else if (status == 'failed') {
            _message = message ?? 'Failed to verify email.';
          }
        });
        return;
      }
      // Get the URL parameters (web / app opened with query params)
      final Uri uri = Uri.base;
      final userId = uri.queryParameters['userId'];
      final secret = uri.queryParameters['secret'];

      if (userId == null || secret == null) {
        setState(() {
          _isVerifying = false;
          _message = 'Check your email for the verification link.';
        });
        return;
      }

      // Get the AuthRepository instance
      final authRepository = GetIt.instance<AuthRepositoryImpl>();

      // Verify the email
      await authRepository.confirmVerification(userId, secret);

      setState(() {
        _isVerifying = false;
        _message = 'Email verified successfully! You can close this window.';
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _message = 'Failed to verify email: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isVerifying)
                const CircularProgressIndicator()
              else if (_message.contains('successfully'))
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                )
              else if (_message.contains('Failed'))
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                )
              else
                const Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Colors.blue,
                ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
