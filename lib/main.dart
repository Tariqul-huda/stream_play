import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './pages/home_page.dart';
import './services/audio_player_service.dart';
import './services/google_auth_service.dart';
import './services/music_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await MusicLocalStorage.instance.init();
  if (!kIsWeb) {
    await AudioPlayerService.initBackground();
  }
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
