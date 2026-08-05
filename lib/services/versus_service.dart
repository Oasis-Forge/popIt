import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum VersusMatchKind { bots, friends }

class VersusPlayerState {
  VersusPlayerState({
    this.score = 0,
    this.combo = 0,
    this.accuracy = 0,
    this.posMs = 0,
    this.state = 'lobby',
    this.displayName = 'You',
    this.isBot = false,
    this.isLocal = false,
    this.botSkill = 0.8,
    this.botPointsPerSec = 220,
  });

  int score;
  int combo;
  double accuracy;
  int posMs;
  String state;
  String displayName;
  bool isBot;
  bool isLocal;

  /// 0.55–1.05: how close the bot stays to its own target pace.
  double botSkill;

  /// Independent scoring pace (not derived from the local player).
  double botPointsPerSec;
}

/// Versus rooms. Bots work locally; friends reserved for Firebase later.
class VersusService extends ChangeNotifier {
  VersusService() : _random = Random();

  final Random _random;

  static const minPlayers = 2;
  static const maxPlayers = 4;
  static const syncHz = 4;

  String? roomCode;
  String? chartId;
  String? chartHash;
  bool isHost = false;
  VersusMatchKind? matchKind;
  int targetPlayerCount = minPlayers;
  final List<VersusPlayerState> players = [];
  DateTime? startAtLocal;
  Timer? _syncTimer;

  VersusPlayerState get local => players.firstWhere(
        (p) => p.isLocal,
        orElse: () => VersusPlayerState(displayName: 'You', isLocal: true),
      );

  List<VersusPlayerState> get rivals =>
      players.where((p) => !p.isLocal).toList();

  /// Back-compat for single-opponent UI callers.
  VersusPlayerState get opponent =>
      rivals.isEmpty ? VersusPlayerState(displayName: 'Rival') : rivals.first;

  bool get canStart =>
      matchKind != null &&
      players.length >= minPlayers &&
      players.length <= maxPlayers &&
      players.any((p) => p.isLocal);

  static String dailySeed([DateTime? now]) {
    final n = (now ?? DateTime.now()).toUtc();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  static String hashChart(String chartId, int noteCount, int durationMs) {
    return base64Url
        .encode(utf8.encode('$chartId|$noteCount|$durationMs'))
        .substring(0, 12);
  }

  static const _botNames = ['Nova', 'Pulse', 'Echo', 'Vibe', 'Glow', 'Bass'];

  void configureLobby({
    required VersusMatchKind kind,
    required int playerCount,
  }) {
    final count = playerCount.clamp(minPlayers, maxPlayers);
    matchKind = kind;
    targetPlayerCount = count;
    players
      ..clear()
      ..add(VersusPlayerState(displayName: 'You', isLocal: true, state: 'ready'));

    if (kind == VersusMatchKind.bots) {
      final botCount = count - 1;
      final names = [..._botNames]..shuffle(_random);
      // Spread skill so someone can beat a sloppy player.
      final skills = <double>[0.62, 0.78, 0.92, 1.05]..shuffle(_random);
      for (var i = 0; i < botCount; i++) {
        players.add(
          VersusPlayerState(
            displayName: names[i % names.length],
            isBot: true,
            state: 'ready',
            botSkill: skills[i % skills.length],
            botPointsPerSec: 160 + _random.nextDouble() * 140,
          ),
        );
      }
      roomCode = 'BOTS';
      isHost = true;
    } else {
      // Friends: seat placeholders until Firebase join fills them.
      roomCode = null;
      isHost = true;
      for (var i = 1; i < count; i++) {
        players.add(
          VersusPlayerState(displayName: 'Open seat $i', state: 'lobby'),
        );
      }
    }
    notifyListeners();
  }

  String createRoom({
    required String chartId,
    required String chartHash,
  }) {
    this.chartId = chartId;
    this.chartHash = chartHash;
    if (matchKind == VersusMatchKind.bots) {
      roomCode = 'BOTS';
    } else {
      roomCode = List.generate(6, (_) => _random.nextInt(36).toRadixString(36))
          .join()
          .toUpperCase();
    }
    isHost = true;
    notifyListeners();
    return roomCode!;
  }

  /// Friends join — reserved. Returns refusal until online is wired.
  String? joinRoom({
    required String code,
    required String chartId,
    required String chartHash,
  }) {
    return 'Online friends coming soon';
  }

  void armStart({Duration countdown = const Duration(seconds: 3)}) {
    startAtLocal = DateTime.now().add(countdown);
    for (final p in players) {
      if (p.state != 'lobby' || p.isBot || p.isLocal) {
        p.state = 'countdown';
      }
    }
    notifyListeners();
  }

  void startSync(void Function() publish) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(milliseconds: (1000 / syncHz).round()),
      (_) => publish(),
    );
  }

  void publishLocal({
    required int score,
    required int combo,
    required double accuracy,
    required int posMs,
    String state = 'playing',
  }) {
    final you = local;
    you
      ..score = score
      ..combo = combo
      ..accuracy = accuracy
      ..posMs = posMs
      ..state = state;

    // Independent bot pace — can lead or trail the player.
    for (final bot in rivals) {
      if (!bot.isBot) continue;
      final secs = posMs / 1000.0;
      final wobble = (_random.nextDouble() - 0.5) * 28;
      final target =
          (secs * bot.botPointsPerSec * bot.botSkill + wobble).round();
      bot
        ..score = target.clamp(0, 999999)
        ..combo = (bot.botSkill * 40 + _random.nextInt(8)).round()
        ..accuracy = (0.72 + bot.botSkill * 0.25).clamp(0.0, 1.0)
        ..posMs = posMs
        ..state = state;
    }
    notifyListeners();
  }

  void leave() {
    _syncTimer?.cancel();
    roomCode = null;
    chartId = null;
    chartHash = null;
    startAtLocal = null;
    matchKind = null;
    targetPlayerCount = minPlayers;
    players.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
