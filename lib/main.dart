import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:nocrastinate/Manager/MindPracticeManager.dart';
import 'package:nocrastinate/Manager/StreaksManager.dart';
import 'package:nocrastinate/Screens/Onboarding/Onboarding11Screen.dart';
import 'package:nocrastinate/Screens/Onboarding/Onboarding2Screen.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/CustomTabbar.dart';
import 'package:nocrastinate/Screens/Onboarding/OnBoarding1Screen.dart';
import 'ApiServices/AuthProvider.dart';
import 'ApiServices/AuthService.dart';
import 'ApiServices/InAppPurchaseService.dart';
import 'ApiServices/LocalNotificationService.dart';
import 'Manager/MoodCheckinManager.dart';
import 'Manager/WidgetManager.dart';
import 'ThemeManager.dart';
import 'Util/AuthWrapper.dart';
import 'Util/ErrorApp.dart';
import 'Util/PermissionHelper.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatewidget') {
    await WidgetManager.updateWidget();
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetManager.initializeWidget();
  await EasyLocalization.ensureInitialized();

  // Register background callback for widget updates
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Auth Service
    AuthService().initialize(
        googleClientId: '956440679907-h4gvmhj5e5atciaqukvuk8790204re7u.apps.googleusercontent.com'
    );
    try {
      print('Initializing In-App Purchase service...');
      await InAppPurchaseService().initialize();
      print('IAP service initialization completed');
    } catch (e) {
      print('Warning: IAP service initialization failed: $e');
      // Don't crash the app if IAP fails to initialize
    }

    // Request permissions early (before initializing notification service)
    try {
      print('Requesting notification permissions...');
      await PermissionHelper.requestAllPermissions();
      print('Permission request completed');
    } catch (e) {
      print('Error requesting permissions: $e');
    }

    // Initialize Local Notification Service
    try {
      await LocalNotificationService().initialize();
      print('Local Notification Service initialized successfully');

      final notificationsEnabled = await LocalNotificationService().areNotificationsEnabled();
      print('Notifications enabled: $notificationsEnabled');

      if (Platform.isAndroid) {
        final exactAlarmsEnabled = await PermissionHelper.canScheduleExactAlarms();
        print('Exact alarms enabled: $exactAlarmsEnabled');

        if (!exactAlarmsEnabled) {
          print('Warning: Exact alarms not enabled - notifications may not work reliably');
        }
      }
    } catch (e) {
      print('Error initializing Local Notification Service: $e');
    }

    // Create providers
    final themeManager = ThemeManager();
    final authProvider = AuthProvider();
    final moodCheckinManager = MoodCheckinManager();
    final mindPracticeManager = MindPracticeManager();
    final streaksManager = StreaksManager();

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('de', 'DE'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('ru', 'RU'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeManager),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: moodCheckinManager),
            ChangeNotifierProvider.value(value: mindPracticeManager),
            ChangeNotifierProvider.value(value: streaksManager),
          ],
          child: const MyApp(),
        ),
      ),
    );

  } catch (e) {
    print('Error initializing app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'Nocrastinate',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // CRITICAL: Add these three lines for EasyLocalization to work
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,

          // Use AuthWrapper as home instead of initialRoute
          home: AuthWrapper(),

          // Define routes for manual navigation
          routes: {
            '/onboarding': (context) => const OnBoarding1Screen(),
            '/home': (context) => CustomTabbarView(),
            '/focus': (context) => CustomTabbarView(initialIndex: 1),
            '/login': (context) => const OnBoarding1Screen(),
            '/purchase': (context) => const Onboarding11Screen(),
            '/onboarding2': (context) => const Onboarding2Screen(),
            '/splash': (context) => const AuthWrapper(),

          },

          // Handle unknown routes
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const OnBoarding1Screen(),
            );
          },

          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}