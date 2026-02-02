import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PlugPlayApp(),
    ),
  );
}

class PlugPlayApp extends StatelessWidget {
  const PlugPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plug & Play AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF41),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        textTheme: GoogleFonts.firaCodeTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
