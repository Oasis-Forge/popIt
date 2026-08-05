import 'package:flutter/foundation.dart';

/// Soft GPGS facade. Local-first until Play Console APP_ID is configured.
class GamesService extends ChangeNotifier {
  bool signedIn = false;
  String? playerId;
  String? displayName;
  String? error;

  /// Flip when `games-ids.xml` has a real APP_ID and `games_services` is wired.
  bool get isConfigured => false;

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> silentSignIn() async {
    if (!isAndroid || !isConfigured) {
      signedIn = false;
      notifyListeners();
      return;
    }
    try {
      signedIn = false;
      playerId = null;
      displayName = null;
      error = null;
    } catch (e) {
      error = e.toString();
      signedIn = false;
    }
    notifyListeners();
  }

  Future<bool> signIn() async {
    if (!isAndroid) {
      error = 'Google Play Games is Android-only.';
      notifyListeners();
      return false;
    }
    if (!isConfigured) {
      error = null;
      notifyListeners();
      return false;
    }
    error = 'Configure Play Games APP_ID in Play Console to enable sign-in.';
    notifyListeners();
    return false;
  }

  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    if (!signedIn) return;
  }

  Future<void> queueOrSubmit({
    required String leaderboardId,
    required int score,
    required void Function(Map<String, dynamic> pending) enqueue,
  }) async {
    if (signedIn) {
      await submitScore(leaderboardId: leaderboardId, score: score);
      return;
    }
    enqueue({
      'leaderboardId': leaderboardId,
      'score': score,
      'atEpochMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> unlockAchievement(String id) async {}

  Future<void> showLeaderboards() async {
    if (!isAndroid || !isConfigured) {
      error = null;
      notifyListeners();
    }
  }
}
