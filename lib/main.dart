import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/game_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PopItApp());
}

class PopItApp extends StatelessWidget {
  const PopItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pop It',
      debugShowCheckedModeBanner: false,
      theme: buildPopItTheme(),
      home: const HomeScreen(),
    );
  }
}
