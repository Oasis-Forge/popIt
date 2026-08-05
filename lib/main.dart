import 'package:flutter/material.dart';

import 'app/app_scope.dart';
import 'data/player_profile.dart';
import 'game/chart_library.dart';
import 'screens/home_screen.dart';
import 'services/games_service.dart';
import 'services/settings_controller.dart';
import 'services/versus_service.dart';
import 'theme/game_theme.dart';
import 'theme/vault_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final services = await AppServices.bootstrap();
    runApp(PopItApp(services: services));
  } catch (e, st) {
    debugPrint('Bootstrap failed: $e\n$st');
    final fallback = await _fallbackServices();
    runApp(PopItApp(services: fallback));
  }
}

Future<AppServices> _fallbackServices() async {
  return AppServices(
    settingsController: SettingsController(SettingsStore(), AppSettings()),
    profileController: ProfileController(ProfileStore(), PlayerProfile()),
    chartLibrary: ChartLibrary(const [
      ChartMeta(
        id: 'demo_beat',
        title: 'Demo Beat',
        artist: 'Pop It',
        bpm: 120,
        durationMs: 32000,
        audioAsset: 'assets/audio/demo_beat.wav',
        chartAsset: 'assets/charts/demo.json',
      ),
    ]),
    gamesService: GamesService(),
    versusService: VersusService(),
  );
}

class PopItApp extends StatelessWidget {
  const PopItApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settingsController,
        builder: (context, _) {
          final palette = VaultPalette.byId(services.settings.themeId);
          return MaterialApp(
            title: 'Pop It',
            debugShowCheckedModeBanner: false,
            theme: buildPopItTheme(palette: palette),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
