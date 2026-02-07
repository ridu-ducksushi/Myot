import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/services/admob_service.dart';
import 'package:petcare/utils/app_logger.dart';

// import 'package:petcare/app/notifications.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:petcare/core/providers/theme_provider.dart';
import 'package:petcare/routes.dart';
import 'package:petcare/ui/theme/app_theme.dart';
import 'package:petcare/app/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Firebase (임시 비활성화)
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  AppLogger.d('Main', 'Supabase 연결 완료');

  // Initialize app services
  await AppBootstrap.initialize();

  // Initialize AdMob
  await AdMobService.initialize();

  // Initialize FCM (임시 비활성화)
  // await initNotifications();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('ko'),
      child: const ProviderScope(child: PetCareApp()),
    ),
  );
}

class PetCareApp extends ConsumerWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0), // 시스템 폰트 크기 변경 무시하고 고정
      ),
      child: MaterialApp.router(
        title: 'PetCare',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: router,
      ),
    );
  }
}