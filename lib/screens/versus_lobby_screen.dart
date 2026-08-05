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
  final _joinCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final services = AppScope.of(context);
    final meta = services.chartLibrary.byId(services.settings.lastChartId);
    final hash = VersusService.hashChart(meta.id, 0, meta.durationMs);
    services.versusService.createRoom(chartId: meta.id, chartHash: hash);
    services.versusService.armStart();
    setState(() => _error = null);
  }

  Future<void> _join() async {
    final services = AppScope.of(context);
    final meta = services.chartLibrary.byId(services.settings.lastChartId);
    final hash = VersusService.hashChart(meta.id, 0, meta.durationMs);
    final err = services.versusService.joinRoom(
      code: _joinCtrl.text,
      chartId: meta.id,
      chartHash: hash,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    services.versusService.armStart();
    setState(() => _error = null);
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
                      versus.roomCode == null
                          ? 'Create or join a room'
                          : 'Room ${versus.roomCode}',
                      style: vaultDisplay(size: 24),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: vaultLabel(size: 11, color: v.missRed),
                      ),
                    ],
                    const SizedBox(height: 20),
                    VaultCta(label: 'CREATE ROOM', onPressed: _create),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _joinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _join,
                      child: const Text('JOIN'),
                    ),
                    const Spacer(),
                    if (versus.roomCode != null)
                      VaultCta(
                        label: 'START MATCH',
                        onPressed: () {
                          Navigator.of(context).push(
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
                        },
                      ),
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
