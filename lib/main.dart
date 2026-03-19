import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pos_app/ui/screens/login_table_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/screens/dashboard_screen.dart';

import 'services/license_service.dart';
import 'services/local_db_service.dart';
import 'services/language_service.dart';
import 'settings/printer_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DB init for Windows
  if (!kIsWeb && Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
  }

  await LocalDbService.seedData();
  await LanguageService.init();
  await PrinterSettings.loadSettings();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    const windowOptions = WindowOptions(
      size: Size(1400, 900),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.setFullScreen(true);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final expired = await LicenseService.isExpired();

  runApp(MyApp(expired: expired));
}

class MyApp extends StatelessWidget {
  final bool expired;
  const MyApp({super.key, required this.expired});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, lang, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            primaryColor: Colors.orange,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              primary: Colors.orange,
              secondary: Colors.orangeAccent,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          home: ExitWrapper(
            child: expired ? const LoginTableScreen() : const DashboardScreen(),
          ),
        );
      },
    );
  }
}

class ExitWrapper extends StatelessWidget {
  final Widget child;
  const ExitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyF,
        ): const ActivateIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyQ,
        ): const DismissIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) async {
              if (!kIsWeb &&
                  (Platform.isWindows ||
                      Platform.isLinux ||
                      Platform.isMacOS)) {
                bool isFull = await windowManager.isFullScreen();
                await windowManager.setFullScreen(!isFull);
              }
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) async {
              if (!kIsWeb &&
                  (Platform.isWindows ||
                      Platform.isLinux ||
                      Platform.isMacOS)) {
                await windowManager.close();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
