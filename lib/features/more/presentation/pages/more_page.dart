import 'package:community/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../language/presentation/pages/language_page.dart';
import '../../../theme/presentation/bloc/theme_bloc.dart';
import '../../../profile/presentation/pages/profile_page.dart'; // Import Profile Page

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Settings",
        showSettingsButton: false,
        actions: [
          IconButton(
            color: Theme.of(context).scaffoldBackgroundColor,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const LanguagePage();
              }));
            },
            icon: const Icon(Icons.language),
          ),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return IconButton(
                color: Theme.of(context).scaffoldBackgroundColor,
                icon: Icon(
                  state is ThemeLoaded && state.theme == AppTheme.dark
                      ? Icons.wb_sunny
                      : Icons.nightlight_round,
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ChangeThemeEvent(
                      state is ThemeLoaded && state.theme == AppTheme.dark
                          ? AppTheme.light
                          : AppTheme.dark));
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile Management"),
            subtitle:
                const Text("Edit profile, change password, delete account"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          const Divider(),
          Center(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutEvent());
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.logout.toUpperCase(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
