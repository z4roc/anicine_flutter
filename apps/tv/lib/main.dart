import 'package:anicinehome_tv/screens/tv_main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force landscape orientation for TV
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const AniCineTVApp());
}

class AniCineTVApp extends StatelessWidget {
  const AniCineTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniCine TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // TV-optimized focus
        focusColor: Colors.white.withOpacity(0.3),
        hoverColor: Colors.white.withOpacity(0.1),
      ),
      home: const TVMainNavigationScreen(),
    );
  }
}