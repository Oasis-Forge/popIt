import 'package:flutter/material.dart';

import '../data/player_profile.dart';
import '../game/chart_library.dart';
import '../services/games_service.dart';
import '../services/settings_controller.dart';
import '../services/versus_service.dart';

class AppServices {
  AppServices({
    required this.settingsController,
    required this.profileController,
    required this.chartLibrary,
    required this.gamesService,
    required this.versusService,
  });

  final SettingsController settingsController;
  final ProfileController profileController;
  final ChartLibrary chartLibrary;
  final GamesService gamesService;
  final VersusService versusService;

  AppSettings get settings => settingsController.settings;
  PlayerProfile get profile => profileController.profile;

  static Future<AppServices> bootstrap() async {
    final settingsStore = SettingsStore();
    final profileStore = ProfileStore();
    final settings = await settingsStore.load();
    final profile = await profileStore.load();
    final charts = await ChartLibrary.load();
    final games = GamesService();
    final versus = VersusService();
    // Fire-and-forget; never block gameplay.
    // ignore: unawaited_futures
    games.silentSignIn();
    return AppServices(
      settingsController: SettingsController(settingsStore, settings),
      profileController: ProfileController(profileStore, profile),
      chartLibrary: charts,
      gamesService: games,
      versusService: versus,
    );
  }

  void dispose() {
    settingsController.dispose();
    profileController.dispose();
    gamesService.dispose();
    versusService.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.services;
  }

  static AppServices? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()?.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services;
}
