import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './pages/login.dart';
import './services/audio_player_service.dart';
import './services/google_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // await AudioPlayerService.initBackground();
  await AudioPlayerService().init();
  // Restore previous Google session silently (non-blocking)
  GoogleAuthService().trySilentSignIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
      // home: HomePage(),
    );
  }
}
