import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/language_bloc.dart';
import '../bloc/language_event.dart';
import '../bloc/language_state.dart';
import '../../../../l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.changeLanguage,
        ),
      ),
      body: Center(
        child: BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, state) {
            if (kDebugMode) {
              print('Current state: $state');
            }
            if (state.languages.isNotEmpty) {
              return ListView.builder(
                itemCount: state.languages.length,
                itemBuilder: (context, index) {
                  var item = state.languages[index];
                  return RadioListTile(
                    value: item.languageCode,
                    groupValue: state.locale.languageCode,
                    secondary: item.languageCode == 'en'
                        ? const Text(
                            '🇺🇸',
                            style: TextStyle(
                              fontSize: 20.0,
                            ),
                          )
                        : item.languageCode == 'fi'
                            ? const Text(
                                '🇫🇮',
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              )
                            : const Text(
                                '🇸🇪',
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                    title: Text(item.language,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                item.languageCode == state.locale.languageCode
                                    ? Colors.blue
                                    : Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .color),
                        key: Key('language_${item.language}')),
                    subtitle: Text(item.subLanguage,
                        style: TextStyle(
                            fontSize: 16.0,
                            color:
                                item.languageCode == state.locale.languageCode
                                    ? Colors.blue
                                    : Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .color),
                        key: Key('sub_language_${item.subLanguage}')),
                    onChanged: (value) {
                      if (kDebugMode) {
                        print('Selected language: $value');
                      }
                      context
                          .read<LocalizationBloc>()
                          .add(LoadLocalization(Locale(value!)));
                    },
                  );
                },
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
