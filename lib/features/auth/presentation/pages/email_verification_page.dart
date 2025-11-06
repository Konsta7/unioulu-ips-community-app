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
      // Get the URL parameters
      final Uri uri = Uri.base;
      final userId = uri.queryParameters['userId'];
      final secret = uri.queryParameters['secret'];

      if (userId == null || secret == null) {
        setState(() {
          _isVerifying = false;
          _message = 'Invalid verification link';
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
              else
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
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
