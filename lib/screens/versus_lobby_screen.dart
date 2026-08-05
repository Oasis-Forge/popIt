import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../game/models.dart';
import '../game/run_config.dart';
import '../game/widgets/vault_decor.dart';
import '../services/versus_service.dart';
import '../theme/game_theme.dart';
import '../theme/vault_palette.dart';
import 'game_screen.dart';

class VersusLobbyScreen extends StatefulWidget {
  const VersusLobbyScreen({super.key});

  @override
  State<VersusLobbyScreen> createState() => _VersusLobbyScreenState();
}

class _VersusLobbyScreenState extends State<VersusLobbyScreen> {
  VersusMatchKind? _kind;
  int _playerCount = VersusService.minPlayers;

  Future<void> _startBots() async {
    final services = AppScope.of(context);
    final versus = services.versusService;
    final meta = services.chartLibrary.byId(services.settings.lastChartId);
    final hash = VersusService.hashChart(meta.id, 0, meta.durationMs);

    versus.configureLobby(kind: VersusMatchKind.bots, playerCount: _playerCount);
    versus.createRoom(chartId: meta.id, chartHash: hash);
    versus.armStart();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          config: RunConfig(
            chartId: versus.chartId ?? 'demo_beat',
            mode: GameMode.classic,
            versusRoom: versus.roomCode,
          ),
        ),
      ),
    );
    versus.leave();
    if (mounted) setState(() => _kind = null);
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    final versus = AppScope.of(context).versusService;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: v.roomGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: versus,
            builder: (context, _) {
              final v = context.vault;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            versus.leave();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded),
                          color: v.paper,
                        ),
                        const Spacer(),
                        Text(
                          'VERSUS',
                          style: vaultLabel(size: 12, color: v.gold),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'How do you want to play?',
                      textAlign: TextAlign.center,
                      style: vaultDisplay(size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2–4 players per session',
                      textAlign: TextAlign.center,
                      style: vaultLabel(
                        size: 10,
                        color: v.paper.withValues(alpha: 0.5),
                        weight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _MatchOption(
                      selected: _kind == VersusMatchKind.bots,
                      enabled: true,
                      title: 'VS BOTS',
                      subtitle: 'Local match against AI rivals',
                      onTap: () => setState(() => _kind = VersusMatchKind.bots),
                    ),
                    const SizedBox(height: 12),
                    _MatchOption(
                      selected: false,
                      enabled: false,
                      title: 'WITH FRIENDS',
                      subtitle: 'Online rooms — coming soon',
                      onTap: () {},
                    ),
                    if (_kind == VersusMatchKind.bots) ...[
                      const SizedBox(height: 28),
                      Text(
                        'PLAYERS',
                        textAlign: TextAlign.center,
                        style: vaultLabel(size: 11, color: v.gold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var n = VersusService.minPlayers;
                              n <= VersusService.maxPlayers;
                              n++) ...[
                            if (n > VersusService.minPlayers)
                              const SizedBox(width: 8),
                            Expanded(
                              child: _CountChip(
                                label: '$n',
                                selected: _playerCount == n,
                                onTap: () => setState(() => _playerCount = n),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You + ${_playerCount - 1} bot${_playerCount - 1 == 1 ? '' : 's'}',
                        textAlign: TextAlign.center,
                        style: vaultLabel(
                          size: 10,
                          color: v.paper.withValues(alpha: 0.45),
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_kind == VersusMatchKind.bots)
                      VaultCta(
                        label: 'START ${_playerCount}P MATCH',
                        shimmer: true,
                        onPressed: _startBots,
                      )
                    else
                      Opacity(
                        opacity: 0.35,
                        child: IgnorePointer(
                          child: VaultCta(
                            label: 'CHOOSE A MODE',
                            onPressed: () {},
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchOption extends StatelessWidget {
  const _MatchOption({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    final border = selected
        ? v.gold
        : v.paper.withValues(alpha: enabled ? 0.28 : 0.12);
    final titleColor = enabled
        ? (selected ? v.gold : v.paper)
        : v.paper.withValues(alpha: 0.35);
    final subColor = v.paper.withValues(alpha: enabled ? 0.5 : 0.28);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: selected ? 2 : 1),
              color: v.plateMid.withValues(alpha: selected ? 0.55 : 0.28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: vaultDisplay(size: 18, color: titleColor)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: vaultLabel(
                          size: 10,
                          color: subColor,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!enabled)
                  Text(
                    'SOON',
                    style: vaultLabel(
                      size: 9,
                      color: v.paper.withValues(alpha: 0.4),
                    ),
                  )
                else if (selected)
                  Icon(Icons.check_circle_rounded, color: v.gold, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vault;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? v.gold : v.paper.withValues(alpha: 0.22),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? v.gold.withValues(alpha: 0.18)
                : v.plateMid.withValues(alpha: 0.35),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: vaultDisplay(
              size: 20,
              color: selected ? v.gold : v.paper,
            ),
          ),
        ),
      ),
    );
  }
}
