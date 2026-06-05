import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'views/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Site Voice Ledger',
        debugShowCheckedModeBanner: false,
        
        // Gorgeous premium dark theme setup
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF00F2FE),
          scaffoldBackgroundColor: const Color(0xFF020617),
          
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00F2FE),
            secondary: const Color(0xFF4FACFE),
            surface: const Color(0xFF0F172A),
            error: Colors.red.shade400,
          ),
          
          // Font customization
          fontFamily: 'Roboto',
          
          // Card styling
          cardTheme: CardThemeData(
            color: const Color(0xFF0F172A),
            elevation: 2,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          // AppBar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0B1329),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          
          // Dialog Theme
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF0B1329),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          
          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const SplashView(),
      ),
    );
  }
}
