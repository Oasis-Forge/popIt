import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RunBest {
  const RunBest({
    required this.score,
    required this.accuracy,
    required this.maxCombo,
    required this.perfect,
    required this.good,
    required this.miss,
    required this.grade,
    required this.atEpochMs,
  });

  final int score;
  final double accuracy;
  final int maxCombo;
  final int perfect;
  final int good;
  final int miss;
  final String grade;
  final int atEpochMs;

  Map<String, dynamic> toJson() => {
        'score': score,
        'accuracy': accuracy,
        'maxCombo': maxCombo,
        'perfect': perfect,
        'good': good,
        'miss': miss,
        'grade': grade,
        'atEpochMs': atEpochMs,
      };

  factory RunBest.fromJson(Map<String, dynamic> json) => RunBest(
        score: json['score'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        maxCombo: json['maxCombo'] as int? ?? 0,
        perfect: json['perfect'] as int? ?? 0,
        good: json['good'] as int? ?? 0,
        miss: json['miss'] as int? ?? 0,
        grade: json['grade'] as String? ?? 'UNCUT',
        atEpochMs: json['atEpochMs'] as int? ?? 0,
      );
}

class PlayerProfile extends ChangeNotifier {
  PlayerProfile({
    Map<String, RunBest>? bests,
    this.runs = 0,
    this.notesHit = 0,
    this.lifetimeScore = 0,
    this.longestCombo = 0,
    this.streakCurrent = 0,
    this.streakBest = 0,
    this.lastPlayedYmd = '',
    this.dailyCompletedYmd = '',
    this.coachCompleted = false,
    this.roadBestStage = 0,
    this.roadBestCleared = 0,
    Set<String>? unlockedThemeIds,
    List<Map<String, dynamic>>? pendingLeaderboardSubmissions,
  })  : bests = bests ?? {},
        unlockedThemeIds = unlockedThemeIds ?? {'disco_vault', 'neon_arcade'},
        pendingLeaderboardSubmissions = pendingLeaderboardSubmissions ?? [];

  final Map<String, RunBest> bests;
  int runs;
  int notesHit;
  int lifetimeScore;
  int longestCombo;
  int streakCurrent;
  int streakBest;
  String lastPlayedYmd;
  String dailyCompletedYmd;
  bool coachCompleted;
  int roadBestStage;
  int roadBestCleared;
  final Set<String> unlockedThemeIds;
  final List<Map<String, dynamic>> pendingLeaderboardSubmissions;

  bool hasPlayedDaily(String ymd) => dailyCompletedYmd == ymd;

  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'bests': bests.map((k, v) => MapEntry(k, v.toJson())),
        'totals': {
          'runs': runs,
          'notesHit': notesHit,
          'lifetimeScore': lifetimeScore,
          'longestCombo': longestCombo,
        },
        'streak': {
          'current': streakCurrent,
          'best': streakBest,
          'lastPlayedYmd': lastPlayedYmd,
        },
        'dailyCompletedYmd': dailyCompletedYmd,
        'coachCompleted': coachCompleted,
        'road': {
          'bestStage': roadBestStage,
          'bestCleared': roadBestCleared,
        },
        'unlockedThemeIds': unlockedThemeIds.toList(),
        'pendingLeaderboardSubmissions': pendingLeaderboardSubmissions,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final bestsRaw = json['bests'] as Map<String, dynamic>? ?? {};
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final streak = json['streak'] as Map<String, dynamic>? ?? {};
    final road = json['road'] as Map<String, dynamic>? ?? {};
    return PlayerProfile(
      bests: bestsRaw.map(
        (k, v) => MapEntry(k, RunBest.fromJson(v as Map<String, dynamic>)),
      ),
      runs: totals['runs'] as int? ?? 0,
      notesHit: totals['notesHit'] as int? ?? 0,
      lifetimeScore: totals['lifetimeScore'] as int? ?? 0,
      longestCombo: totals['longestCombo'] as int? ?? 0,
      streakCurrent: streak['current'] as int? ?? 0,
      streakBest: streak['best'] as int? ?? 0,
      lastPlayedYmd: streak['lastPlayedYmd'] as String? ?? '',
      dailyCompletedYmd: json['dailyCompletedYmd'] as String? ?? '',
      coachCompleted: json['coachCompleted'] as bool? ?? false,
      roadBestStage: road['bestStage'] as int? ?? 0,
      roadBestCleared: road['bestCleared'] as int? ?? 0,
      unlockedThemeIds: {
        ...(json['unlockedThemeIds'] as List<dynamic>? ?? ['disco_vault'])
            .cast<String>(),
        'neon_arcade', // free starter for older profiles
      },
      pendingLeaderboardSubmissions:
          (json['pendingLeaderboardSubmissions'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
    );
  }

  /// Returns true if this run set a new personal best for [key].
  bool recordRun({
    required String key,
    required RunBest best,
  }) {
    final prev = bests[key];
    final isNewBest = prev == null || best.score > prev.score;
    if (isNewBest) {
      bests[key] = best;
    }
    runs += 1;
    notesHit += best.perfect + best.good;
    lifetimeScore += best.score;
    if (best.maxCombo > longestCombo) longestCombo = best.maxCombo;
    _touchStreak();
    notifyListeners();
    return isNewBest;
  }

  void markDailyCompleted(String ymd) {
    if (dailyCompletedYmd == ymd) return;
    dailyCompletedYmd = ymd;
    notifyListeners();
  }

  void markCoachCompleted() {
    if (coachCompleted) return;
    coachCompleted = true;
    notifyListeners();
  }

  void recordRoadProgress({required int stageIndex, required int cleared}) {
    var changed = false;
    if (stageIndex > roadBestStage) {
      roadBestStage = stageIndex;
      changed = true;
    }
    if (cleared > roadBestCleared) {
      roadBestCleared = cleared;
      changed = true;
    }
    if (changed) {
      _touchStreak();
      notifyListeners();
    }
  }

  void unlockTheme(String id) {
    if (unlockedThemeIds.add(id)) notifyListeners();
  }

  void enqueueLeaderboard(Map<String, dynamic> pending) {
    pendingLeaderboardSubmissions.add(pending);
    notifyListeners();
  }

  void _touchStreak() {
    final now = DateTime.now().toUtc();
    final ymd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (lastPlayedYmd == ymd) return;
    final yesterday = now.subtract(const Duration(days: 1));
    final yYmd =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    streakCurrent = lastPlayedYmd == yYmd ? streakCurrent + 1 : 1;
    if (streakCurrent > streakBest) streakBest = streakCurrent;
    lastPlayedYmd = ymd;
  }
}

class ProfileStore {
  static const _key = 'popit.profile.v1';

  Future<PlayerProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return PlayerProfile();
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerProfile();
    }
  }

  Future<void> save(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}

class ProfileController extends ChangeNotifier {
  ProfileController(this._store, this.profile) {
    profile.addListener(_forward);
  }

  final ProfileStore _store;
  final PlayerProfile profile;

  void _forward() {
    notifyListeners();
    _store.save(profile);
  }

  void unlockTheme(String id) => profile.unlockTheme(id);

  void enqueueLeaderboard(Map<String, dynamic> pending) =>
      profile.enqueueLeaderboard(pending);

  @override
  void dispose() {
    profile.removeListener(_forward);
    super.dispose();
  }
}
