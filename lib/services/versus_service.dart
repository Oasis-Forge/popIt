import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

class VersusPlayerState {
  VersusPlayerState({
    this.score = 0,
    this.combo = 0,
    this.accuracy = 0,
    this.posMs = 0,
    this.state = 'lobby',
    this.displayName = 'You',
  });

  int score;
  int combo;
  double accuracy;
  int posMs;
  String state;
  String displayName;
}

/// Versus rooms. Uses an in-memory mock until Firebase RTDB is wired.
/// API mirrors the planned RTDB shape so swapping transport is local.
class VersusService extends ChangeNotifier {
  VersusService() : _random = Random();

  final Random _random;
  String? roomCode;
  String? chartId;
  String? chartHash;
  bool isHost = false;
  VersusPlayerState local = VersusPlayerState();
  VersusPlayerState opponent = VersusPlayerState(displayName: 'Rival');
  DateTime? startAtLocal;
  Timer? _syncTimer;
  static const syncHz = 4;

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

  String createRoom({
    required String chartId,
    required String chartHash,
  }) {
    this.chartId = chartId;
    this.chartHash = chartHash;
    roomCode = List.generate(6, (_) => _random.nextInt(36).toRadixString(36))
        .join()
        .toUpperCase();
    isHost = true;
    local = VersusPlayerState(displayName: 'You', state: 'ready');
    opponent = VersusPlayerState(displayName: 'Waiting…', state: 'lobby');
    notifyListeners();
    return roomCode!;
  }

  /// Returns null on success, otherwise a refusal reason.
  String? joinRoom({
    required String code,
    required String chartId,
    required String chartHash,
  }) {
    if (code.trim().length < 4) return 'Invalid room code';
    // Mock rooms accept any code; refuse only on explicit hash mismatch
    // when a host chart was already set in-session.
    if (this.chartHash != null && this.chartHash != chartHash) {
      return 'chartHash mismatch — refuse to start';
    }
    roomCode = code.trim().toUpperCase();
    this.chartId = chartId;
    this.chartHash = chartHash;
    isHost = false;
    local = VersusPlayerState(displayName: 'You', state: 'ready');
    opponent = VersusPlayerState(displayName: 'Host', state: 'ready');
    notifyListeners();
    return null;
  }

  void armStart({Duration countdown = const Duration(seconds: 3)}) {
    startAtLocal = DateTime.now().add(countdown);
    local.state = 'countdown';
    opponent.state = 'countdown';
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
    local
      ..score = score
      ..combo = combo
      ..accuracy = accuracy
      ..posMs = posMs
      ..state = state;
    // Local mock opponent drift for UI polish without Firebase.
    opponent
      ..score = (score * 0.92).round()
      ..combo = combo > 0 ? combo - 1 : 0
      ..accuracy = (accuracy * 0.95).clamp(0, 1)
      ..posMs = posMs
      ..state = state;
    notifyListeners();
  }

  void leave() {
    _syncTimer?.cancel();
    roomCode = null;
    chartId = null;
    chartHash = null;
    startAtLocal = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
