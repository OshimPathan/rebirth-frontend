import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/services/theme_service.dart';
import 'package:rebirth_draft_2/pages/Splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(
    ChangeNotifierProvider.value(value: themeService, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rebirth - Mental Health Support',
          themeMode: themeService.themeMode,

          // Light Theme
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: AppColors.primaryColor,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryColor,
              brightness: Brightness.light,
              surface: AppColors.backgroundColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.textColor,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textColor,
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: AppColors.textColor),
              bodyMedium: TextStyle(color: AppColors.textColor),
              titleLarge: TextStyle(color: AppColors.textColor),
            ),
            cardTheme: const CardThemeData(
              color: AppColors.surfaceColor,
              elevation: 2,
            ),
            useMaterial3: true,
          ),

          // Dark Theme
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: AppColors.darkPrimaryColor,
            scaffoldBackgroundColor: AppColors.darkBackgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkPrimaryColor,
              brightness: Brightness.dark,
              surface: AppColors.darkBackgroundColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkSurfaceColor,
              foregroundColor: AppColors.darkTextColor,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryColor,
                foregroundColor: AppColors.darkTextColor,
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: AppColors.darkTextColor),
              bodyMedium: TextStyle(color: AppColors.darkTextColor),
              titleLarge: TextStyle(color: AppColors.darkTextColor),
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkSurfaceColor,
              elevation: 2,
            ),
            useMaterial3: true,
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
