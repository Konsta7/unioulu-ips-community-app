import 'dart:developer' as developer;

import 'package:community/core/theme/theme_constants.dart';
import 'package:community/core/widgets/custom_text_field.dart';
import 'package:community/core/widgets/password_text_field.dart';
import 'package:community/features/auth/presentation/pages/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../language/presentation/pages/language_page.dart';
import '../../../theme/presentation/bloc/theme_bloc.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'password_reset_screen.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    //TODO: remove test logout code
    // perform logout
    // context.read<AuthBloc>().add(LogoutEvent());
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      color: Theme.of(context).textTheme.headlineSmall!.color,
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LanguagePage();
                        }));
                      },
                      icon: const Icon(Icons.language),
                    ),
                    BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, state) {
                        return IconButton(
                          color:
                              Theme.of(context).textTheme.headlineSmall!.color,
                          icon: Icon(
                            state is ThemeLoaded && state.theme == AppTheme.dark
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                          ),
                          onPressed: () {
                            context.read<ThemeBloc>().add(ChangeThemeEvent(
                                state is ThemeLoaded &&
                                        state.theme == AppTheme.dark
                                    ? AppTheme.light
                                    : AppTheme.dark));
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.defaultPadding),
                Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.login,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    const SizedBox(height: AppSpacing.extraLargePadding),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          flex: 1,
                          child: Image.asset(
                            "assets/images/unioululogo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.extraLargePadding),
                  ],
                ),
                Row(
                  children: [
                    const Spacer(),
                    Expanded(
                      flex: 8,
                      child: Form(
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              hintText: AppLocalizations.of(context)!.yourEmail,
                              prefixIcon: Icons.email_outlined,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: AppSpacing.defaultPadding),
                              // Password field
                              child: PasswordTextField(
                                controller: passwordController,
                                textInputAction: TextInputAction.done,
                                hintText:
                                    AppLocalizations.of(context)!.yourPassword,
                              ),
                            ),
                            // Forgot password
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: AppSpacing.smallPadding,
                                  top: AppSpacing.extraSmallPadding),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .forgotPassword,
                                    style: TextStyle(
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .fontSize,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ResetPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: AppSpacing.extraSmallPadding),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .resetPassword,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .fontSize,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.defaultPadding),
                            // Login button
                            CustomButton(
                              text: AppLocalizations.of(context)!.login,
                              onPressed: () {
                                developer.log(
                                    "Login button pressed: ${emailController.text} ${passwordController.text}");
                                context.read<AuthBloc>().add(LoginEvent(
                                    email: emailController.text,
                                    password: passwordController.text));
                              },
                              padding: 20.0,
                              minimumSize: Size(200, 20),
                            ),
                            const SizedBox(height: AppSpacing.defaultPadding),
                            // Don't have an account
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "${AppLocalizations.of(context)!.dontHaveAnAccount} ",
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return RegisterPage();
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.register,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.defaultPadding),
                            const SizedBox(height: AppSpacing.defaultPadding),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
