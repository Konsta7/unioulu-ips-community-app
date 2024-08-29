import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:appwrite/appwrite.dart';
import 'package:community/features/auth/presentation/pages/register_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'core/pages/main_page.dart';
import 'core/pages/splash_page.dart';
import 'core/services/dependency_injection.dart';
import 'core/utils/config.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/domain/usecases/authenticate_anonymous.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/events/data/models/event_model.dart';
import 'features/home/data/models/topic_model.dart';
import 'features/language/presentation/bloc/language_event.dart';
import 'features/theme/presentation/bloc/theme_bloc.dart';
import 'features/theme/domain/usecases/get_theme.dart';
import 'features/theme/domain/usecases/set_theme.dart';
import 'features/language/presentation/bloc/language_bloc.dart';
import 'features/language/domain/usecases/get_languages.dart';
import 'features/language/domain/usecases/set_language.dart';
import 'features/language/domain/usecases/get_saved_language.dart';
import 'core/theme/app_theme.dart';
import 'features/language/data/models/language_model.dart';
import 'features/theme/data/models/theme_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeDatabase();
  _initializeAppwrite();
  setupLocator();

  runApp(const MyApp());
}

Future<void> _initializeDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      LanguageModelSchema,
      ThemeModelSchema,
      UserModelSchema,
      TopicModelSchema,
      EventModelSchema,
    ],
    directory: dir.path,
  );
  locator.registerSingleton<Isar>(isar);
}

void _initializeAppwrite() {
  final client = Client()
    ..setEndpoint(appwriteEndpoint)
    ..setProject(appwriteProjectId)
    ..setSelfSigned(status: true); // Only for development

  // Register Client and Databases as Singletons
  locator.registerSingleton<Client>(client);
  locator.registerSingleton<Account>(Account(client));
  locator
      .registerSingleton<Databases>(Databases(client)); // Registering Databases
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeBloc(
            getTheme: locator<GetTheme>(),
            setTheme: locator<SetTheme>(),
          )..add(LoadThemeEvent()),
        ),
        BlocProvider(
          create: (context) => LocalizationBloc(
            getLanguages: locator<GetLanguages>(),
            setLanguage: locator<SetLanguage>(),
            getSavedLanguage: locator<GetSavedLanguage>(),
          )..add(LoadSavedLocalization()),
        ),
        BlocProvider(
          create: (context) => AuthBloc(
            login: locator<Login>(),
            logout: locator<Logout>(),
            register: locator<Register>(),
            updateProfile: locator<UpdateProfile>(),
            authenticateAnonymous: locator<AuthenticateAnonymous>(),
            account: locator<Account>(),
          ),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          ThemeData themeData = AppThemeData.lightTheme;
          if (state is ThemeLoaded && state.theme == AppTheme.Dark) {
            themeData = AppThemeData.darkTheme;
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'IPS Community App',
            theme: themeData,
            locale:
                context.select((LocalizationBloc bloc) => bloc.state.locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashPage(),
              '/': (context) => const MainPage(),
              '/register': (context) => RegisterPage(),
              '/login': (context) => LoginPage(),
            },
          );
        },
      ),
    );
  }
}
