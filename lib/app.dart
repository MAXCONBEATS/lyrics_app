import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart';
import 'ui/screens/tracks_screen.dart';

class LyricsApp extends ConsumerWidget {
  const LyricsApp({super.key});

  static const dominantColor = Color(0xFF210B2C);
  static const secondaryColor = Color(0xFFBC96E6);
  static const accentColor = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbInit = ref.watch(databaseProvider);

    const double bodySize = 26.0;
    const double titleSize = 42.0;
    const double headlineSize = 36.0;
    const double labelSize = 18.0;

    final textShadow = Shadow(
      color: Colors.black.withValues(alpha: 0.7),
      blurRadius: 3,
      offset: const Offset(0.5, 0.5),
    );

    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'AccidentalPresidency',
      colorScheme: ColorScheme.fromSeed(
        seedColor: dominantColor,
        primary: dominantColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        brightness: Brightness.dark,
        surface: dominantColor,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: bodySize, shadows: [textShadow]),
        bodyMedium: TextStyle(fontSize: bodySize, shadows: [textShadow]),
        bodySmall: TextStyle(fontSize: bodySize * 0.85, shadows: [textShadow]),
        titleMedium: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            shadows: [textShadow]),
        titleLarge: TextStyle(
            fontSize: headlineSize,
            fontWeight: FontWeight.bold,
            shadows: [textShadow]),
        labelLarge: TextStyle(fontSize: labelSize, shadows: [textShadow]),
      ),
    );

    return MaterialApp(
      title: 'Lyrics App',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dominantColor,
                secondaryColor,
                accentColor,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: child!,
        );
      },
      theme: theme,
      home: dbInit.when(
        data: (_) => const TracksScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Ошибка БД: $e')),
        ),
      ),
    );
  }
}