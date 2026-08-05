import '../game/models.dart';
import 'player_profile.dart';

class ThemeUnlockInfo {
  const ThemeUnlockInfo({
    required this.id,
    required this.name,
    required this.rule,
  });

  final String id;
  final String name;
  final String rule;
}

class UnlockProgress {
  const UnlockProgress({
    required this.themeId,
    required this.themeName,
    required this.label,
    required this.current,
    required this.target,
  });

  final String themeId;
  final String themeName;
  final String label;
  final int current;
  final int target;

  double get fraction => target <= 0 ? 1 : (current / target).clamp(0.0, 1.0);
}

/// Neon Arcade is a free starter; Disco Vault is always free.
const kFreeThemeIds = {'disco_vault', 'neon_arcade'};

const kThemeUnlockCatalog = <ThemeUnlockInfo>[
  ThemeUnlockInfo(
    id: 'aurora_ice',
    name: 'Aurora Ice',
    rule: 'Reach a ×100 combo in one run',
  ),
  ThemeUnlockInfo(
    id: 'sunset_bakery',
    name: 'Sunset Bakery',
    rule: 'Clear a run with FLAWLESS grade',
  ),
  ThemeUnlockInfo(
    id: 'midnight_mono',
    name: 'Midnight Mono',
    rule: 'Score any points in Versus',
  ),
];

String unlockRuleFor(String themeId) {
  for (final info in kThemeUnlockCatalog) {
    if (info.id == themeId) return info.rule;
  }
  if (kFreeThemeIds.contains(themeId)) return 'Starter theme';
  return 'Unlock by playing';
}

/// Apply unlocks for this run; returns newly unlocked theme ids.
List<ThemeUnlockInfo> applyThemeUnlocks({
  required PlayerProfile profile,
  required RunResult result,
  required bool versus,
}) {
  final newly = <ThemeUnlockInfo>[];

  void tryUnlock(ThemeUnlockInfo info) {
    if (profile.unlockedThemeIds.contains(info.id)) return;
    profile.unlockTheme(info.id);
    newly.add(info);
  }

  if (result.maxCombo >= 100) {
    tryUnlock(kThemeUnlockCatalog[0]);
  }
  if (result.grade == 'FLAWLESS') {
    tryUnlock(kThemeUnlockCatalog[1]);
  }
  if (versus && result.score > 0) {
    tryUnlock(kThemeUnlockCatalog[2]);
  }

  return newly;
}

/// Next locked theme progress to show on results (priority order).
UnlockProgress? nextUnlockProgress({
  required PlayerProfile profile,
  required RunResult result,
  required bool versus,
}) {
  if (!profile.unlockedThemeIds.contains('aurora_ice')) {
    return UnlockProgress(
      themeId: 'aurora_ice',
      themeName: 'Aurora Ice',
      label: 'combo',
      current: result.maxCombo.clamp(0, 100),
      target: 100,
    );
  }
  if (!profile.unlockedThemeIds.contains('sunset_bakery')) {
    final flawless = result.grade == 'FLAWLESS';
    return UnlockProgress(
      themeId: 'sunset_bakery',
      themeName: 'Sunset Bakery',
      label: 'FLAWLESS',
      current: flawless ? 1 : 0,
      target: 1,
    );
  }
  if (!profile.unlockedThemeIds.contains('midnight_mono')) {
    return UnlockProgress(
      themeId: 'midnight_mono',
      themeName: 'Midnight Mono',
      label: 'versus score',
      current: versus && result.score > 0 ? 1 : 0,
      target: 1,
    );
  }
  return null;
}
