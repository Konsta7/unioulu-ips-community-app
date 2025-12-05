import 'package:appwrite/appwrite.dart';
import 'package:community/features/community/service/community_service.dart';
import 'package:community/features/events/repository/event_repository.dart';
import 'package:community/features/surveys/service/survey_service.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/authenticate_anonymous.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/domain/usecases/update_profile.dart';
import '../../features/language/data/datasources/language_local_data_source.dart';
import '../../features/language/data/repositories/language_repository_impl.dart';
import '../../features/language/domain/usecases/get_languages.dart';
import '../../features/language/domain/usecases/get_saved_language.dart';
import '../../features/language/domain/usecases/set_language.dart';
import '../../features/theme/data/datasources/theme_local_data_source.dart';
import '../../features/theme/data/repositories/theme_repository_impl.dart';
import '../../features/theme/domain/usecases/get_theme.dart';
import '../../features/theme/domain/usecases/set_theme.dart';
import 'http_appwrite_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  _registerThemeDependencies();
  _registerLanguageDependencies();
  _registerAuthDependencies();
  _registerCommonServices();
}

void _registerThemeDependencies() {
  locator.registerLazySingleton<GetTheme>(() {
    final themeLocalDataSource = ThemeLocalDataSourceImpl(locator<Isar>());
    final themeRepository = ThemeRepositoryImpl(themeLocalDataSource);
    return GetTheme(themeRepository);
  });

  locator.registerLazySingleton<SetTheme>(() {
    final themeLocalDataSource = ThemeLocalDataSourceImpl(locator<Isar>());
    final themeRepository = ThemeRepositoryImpl(themeLocalDataSource);
    return SetTheme(themeRepository);
  });
}

void _registerLanguageDependencies() {
  locator.registerLazySingleton<GetLanguages>(() {
    final languageLocalDataSource =
        LanguageLocalDataSourceImpl(locator<Isar>());
    final languageRepository = LanguageRepositoryImpl(languageLocalDataSource);
    return GetLanguages(languageRepository);
  });

  locator.registerLazySingleton<SetLanguage>(() {
    final languageLocalDataSource =
        LanguageLocalDataSourceImpl(locator<Isar>());
    final languageRepository = LanguageRepositoryImpl(languageLocalDataSource);
    return SetLanguage(languageRepository);
  });

  locator.registerLazySingleton<GetSavedLanguage>(() {
    final languageLocalDataSource =
        LanguageLocalDataSourceImpl(locator<Isar>());
    final languageRepository = LanguageRepositoryImpl(languageLocalDataSource);
    return GetSavedLanguage(languageRepository);
  });
}

void _registerAuthDependencies() {
  final authRemoteDataSource = AuthRemoteDataSource(locator<Account>());
  final authRepository =
      AuthRepositoryImpl(authRemoteDataSource, locator<Isar>());

  locator.registerSingleton<AuthRemoteDataSource>(authRemoteDataSource);
  locator.registerSingleton<AuthRepositoryImpl>(authRepository);

  // TODO: Deep link service disabled - uni_links3 plugin causes rendering loop

  locator.registerLazySingleton<Login>(() => Login(authRepository));
  locator.registerLazySingleton<Logout>(() => Logout(authRepository));
  locator.registerLazySingleton<Register>(() => Register(authRepository));
  locator.registerLazySingleton<UpdateProfile>(
      () => UpdateProfile(authRepository));
  locator.registerLazySingleton<AuthenticateAnonymous>(
      () => AuthenticateAnonymous(authRepository));
}

void _registerCommonServices() {
  locator.registerLazySingleton<AppwriteService>(() => AppwriteService());

  locator.registerLazySingleton<EventRepository>(() => EventRepository());
  locator.registerLazySingleton<CommunityService>(
      () => CommunityService(appwriteService: locator<AppwriteService>()));
  locator.registerLazySingleton<SurveyService>(
      () => SurveyService(appwriteService: locator<AppwriteService>()));
}
