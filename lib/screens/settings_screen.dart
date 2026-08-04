import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../services/settings_controller.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';
import 'calibration_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: VaultColors.roomGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              services.settingsController,
              services.profileController,
              services.gamesService,
            ]),
            builder: (context, _) {
              final s = services.settings;
              final profile = services.profile;
              final games = services.gamesService;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: VaultColors.paper,
                      ),
                      const Spacer(),
                      Text(
                        'SETTINGS',
                        style: vaultLabel(size: 12, color: VaultColors.gold),
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
                              return;
                            }
                            s.update((v) => v.themeId = p.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Board scale', style: vaultDisplay(size: 18)),
                  for (final scale in BoardScale.values)
                    ListTile(
                      title: Text(scale.name),
                      trailing: s.boardScale == scale
                          ? const Icon(Icons.check, color: VaultColors.gold)
                          : null,
                      onTap: () => s.update((x) => x.boardScale = scale),
                    ),
                  SwitchListTile(
                    title: const Text('Haptics'),
                    value: s.hapticsEnabled,
                    onChanged: (v) => s.update((x) => x.hapticsEnabled = v),
                  ),
                  SwitchListTile(
                    title: const Text('Reduce motion'),
                    value: s.reduceMotion,
                    onChanged: (v) => s.update((x) => x.reduceMotion = v),
                  ),
                  SwitchListTile(
                    title: const Text('Casual 3×3 board'),
                    subtitle: const Text('Smaller comfort grid for rhythm'),
                    value: s.casualBoard,
                    onChanged: (v) => s.update((x) => x.casualBoard = v),
                  ),
                  ListTile(
                    title: Text('SFX volume ${(s.sfxVolume * 100).round()}%'),
                    subtitle: Slider(
                      value: s.sfxVolume,
                      onChanged: (v) => s.update((x) => x.sfxVolume = v),
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
                      color: VaultColors.paper.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
