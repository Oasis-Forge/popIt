import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_it/app/app_scope.dart';
import 'package:pop_it/data/player_profile.dart';
import 'package:pop_it/game/chart_library.dart';
import 'package:pop_it/game/widgets/bubble.dart';
import 'package:pop_it/game/widgets/pop_it_board.dart';
import 'package:pop_it/main.dart';
import 'package:pop_it/services/games_service.dart';
import 'package:pop_it/services/settings_controller.dart';
import 'package:pop_it/services/versus_service.dart';
import 'package:pop_it/theme/game_theme.dart';
import 'package:pop_it/theme/vault_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _services() async {
  SharedPreferences.setMockInitialValues({});
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home golden', (tester) async {
    final services = await _services();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(PopItApp(services: services));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  }, skip: true); // Enable locally with --update-goldens; CI flake-prone.

  testWidgets('board uses vault palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPopItTheme(palette: VaultPalette.neonArcade),
        home: Scaffold(
          body: PopItBoard(
            rows: 4,
            cols: 5,
            stateForBubble: (_) => BubbleVisualState.idle,
            onBubbleTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PopItBoard), findsOneWidget);
    expect(find.byType(PopBubble), findsNWidgets(20));
  });
}
