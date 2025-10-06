// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get welcome => 'Tervetuloa';

  @override
  String get appName => 'WeConnect';

  @override
  String get changeLanguage => 'Vaihda kieltä';

  @override
  String get username => 'Käyttäjätunnus';

  @override
  String get name => 'Nimi';

  @override
  String get login => 'Kirjaudu sisään';

  @override
  String get register => 'Rekisteröidy';

  @override
  String get logout => 'Kirjaudu ulos';

  @override
  String get email => 'Sähköposti';

  @override
  String get password => 'Salasana';

  @override
  String get forgotPassword => 'Unohditko salasanasi';

  @override
  String get sendResetLink => 'Lähetä palautuslinkki';

  @override
  String get resetPassword => 'Nollaa salasana';

  @override
  String get dontHaveAnAccount => 'Eikö sinulla ole tiliä?';

  @override
  String get alreadyHaveAnAccount => 'Onko sinulla jo tili?';

  @override
  String get yourName => 'Nimesi';

  @override
  String get yourEmail => 'Sähköpostisi';

  @override
  String get yourPassword => 'Salasanasi';
}
