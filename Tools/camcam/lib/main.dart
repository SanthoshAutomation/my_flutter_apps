import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final storage = StorageService();
  await storage.init();

  runApp(DeutschMeisterApp(storage: storage));
}

class DeutschMeisterApp extends StatelessWidget {
  final StorageService storage;
  const DeutschMeisterApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeutschMeister',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF533483),
          secondary: Colors.amber,
          surface: Color(0xFF1a1a2e),
        ),
        scaffoldBackgroundColor: const Color(0xFF0d0d1a),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0d0d1a),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1a1a2e),
          indicatorColor: const Color(0xFF533483),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600);
            }
            return const TextStyle(color: Colors.white54, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white, size: 24);
            }
            return const IconThemeData(color: Colors.white54, size: 24);
          }),
        ),
        useMaterial3: true,
      ),
      home: storage.isOnboardingComplete && storage.hasApiKey
          ? HomeScreen(storage: storage)
          : OnboardingScreen(storage: storage),
    );
  }
}
