import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../game/chart_library.dart';
import '../services/settings_controller.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';
import 'calibration_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        services.settingsController,
        services.profileController,
        services.gamesService,
      ]),
      builder: (context, _) {
        final v = context.vault;
        final s = services.settings;
        final profile = services.profile;
        final games = services.gamesService;
        final charts = services.chartLibrary.charts;
        final selectedChart = charts.any((c) => c.id == s.lastChartId)
            ? s.lastChartId
            : charts.first.id;

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: v.roomGradient),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: v.paper,
                      ),
                      const Spacer(),
                      Text(
                        'SETTINGS',
                        style: vaultLabel(size: 12, color: v.gold),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Theme', style: vaultDisplay(size: 18)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in VaultPalette.all)
                        ChoiceChip(
                          label: Text(
                            p.locked &&
                                    !profile.unlockedThemeIds.contains(p.id)
                                ? '${p.name} (locked)'
                                : p.name,
                          ),
                          selected: s.themeId == p.id,
                          onSelected: (_) {
                            if (p.locked &&
                                !profile.unlockedThemeIds.contains(p.id)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Unlock this theme by playing',
                                    style: vaultLabel(size: 12),
                                  ),
                                  backgroundColor: v.plateDeep,
                                ),
                              );
                              return;
                            }
                            s.update((settings) => settings.themeId = p.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Sound', style: vaultDisplay(size: 18)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedChart,
                    dropdownColor: v.plateMid,
                    decoration: const InputDecoration(
                      labelText: 'Track',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in charts)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.title} · ${c.bpm} BPM'),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) {
                        s.update((x) => x.lastChartId = id);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _trackBlurb(services.chartLibrary.byId(selectedChart)),
                    style: vaultLabel(
                      size: 10,
                      color: v.paper.withValues(alpha: 0.45),
                      weight: FontWeight.w400,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Mute music'),
                    value: s.musicMuted,
                    onChanged: (val) => s.update((x) => x.musicMuted = val),
                  ),
                  ListTile(
                    title: Text(
                      'Music volume ${(s.musicVolume * 100).round()}%',
                    ),
                    subtitle: Slider(
                      value: s.musicVolume,
                      onChanged: s.musicMuted
                          ? null
                          : (val) => s.update((x) => x.musicVolume = val),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Mute SFX'),
                    value: s.sfxMuted,
                    onChanged: (val) => s.update((x) => x.sfxMuted = val),
                  ),
                  ListTile(
                    title: Text('SFX volume ${(s.sfxVolume * 100).round()}%'),
                    subtitle: Slider(
                      value: s.sfxVolume,
                      onChanged: s.sfxMuted
                          ? null
                          : (val) => s.update((x) => x.sfxVolume = val),
                    ),
                  ),
                  ListTile(
                    title: Text('Audio offset ${s.audioOffsetMs} ms'),
                    subtitle: const Text('Tap Calibration to measure'),
                    trailing: const Icon(Icons.tune),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CalibrationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Board scale', style: vaultDisplay(size: 18)),
                  for (final scale in BoardScale.values)
                    ListTile(
                      title: Text(scale.name),
                      trailing: s.boardScale == scale
                          ? Icon(Icons.check, color: v.gold)
                          : null,
                      onTap: () => s.update((x) => x.boardScale = scale),
                    ),
                  SwitchListTile(
                    title: const Text('Haptics'),
                    value: s.hapticsEnabled,
                    onChanged: (val) =>
                        s.update((x) => x.hapticsEnabled = val),
                  ),
                  SwitchListTile(
                    title: const Text('Reduce motion'),
                    value: s.reduceMotion,
                    onChanged: (val) => s.update((x) => x.reduceMotion = val),
                  ),
                  SwitchListTile(
                    title: const Text('Casual 3×3 board'),
                    subtitle: const Text('Smaller comfort grid for rhythm'),
                    value: s.casualBoard,
                    onChanged: (val) => s.update((x) => x.casualBoard = val),
                  ),
                  if (games.isAndroid) ...[
                    const SizedBox(height: 12),
                    Text('Google Play Games', style: vaultDisplay(size: 18)),
                    ListTile(
                      title: Text(
                        games.signedIn
                            ? (games.displayName ?? 'Signed in')
                            : 'Not signed in',
                      ),
                      subtitle: games.error != null
                          ? Text(games.error!)
                          : const Text('Local profile stays authoritative'),
                      trailing: TextButton(
                        onPressed: () async {
                          await games.signIn();
                        },
                        child: const Text('SIGN IN'),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => games.showLeaderboards(),
                      child: const Text('LEADERBOARDS'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Streak ${profile.streakCurrent} · Best ${profile.streakBest} · Runs ${profile.runs}',
                    style: vaultLabel(
                      size: 11,
                      color: v.paper.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _trackBlurb(ChartMeta c) =>
      '${c.artist} · ${(c.durationMs / 1000).round()}s';
}
