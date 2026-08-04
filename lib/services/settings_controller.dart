import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BoardScale { compact, standard, chunky }

class AppSettings extends ChangeNotifier {
  AppSettings({
    this.themeId = 'disco_vault',
    this.boardScale = BoardScale.standard,
    this.audioOffsetMs = 0,
    this.sfxVolume = 0.85,
    this.hapticsEnabled = true,
    this.reduceMotion = false,
    this.casualBoard = false,
    this.lastChartId = 'demo_beat',
    this.lastDifficulty = 'normal',
    this.lastMode = 'classic',
  });

  String themeId;
  BoardScale boardScale;
  int audioOffsetMs;
  double sfxVolume;
  bool hapticsEnabled;
  bool reduceMotion;
  bool casualBoard;
  String lastChartId;
  String lastDifficulty;
  String lastMode;

  double get boardMaxWidth => switch (boardScale) {
        BoardScale.compact => 360,
        BoardScale.standard => 420,
        BoardScale.chunky => 480,
      };

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'themeId': themeId,
        'boardScale': boardScale.name,
        'audioOffsetMs': audioOffsetMs,
        'sfxVolume': sfxVolume,
        'hapticsEnabled': hapticsEnabled,
        'reduceMotion': reduceMotion,
        'casualBoard': casualBoard,
        'lastChartId': lastChartId,
        'lastDifficulty': lastDifficulty,
        'lastMode': lastMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeId: json['themeId'] as String? ?? 'disco_vault',
      boardScale: BoardScale.values.firstWhere(
        (e) => e.name == json['boardScale'],
        orElse: () => BoardScale.standard,
      ),
      audioOffsetMs: json['audioOffsetMs'] as int? ?? 0,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 0.85,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      casualBoard: json['casualBoard'] as bool? ?? false,
      lastChartId: json['lastChartId'] as String? ?? 'demo_beat',
      lastDifficulty: json['lastDifficulty'] as String? ?? 'normal',
      lastMode: json['lastMode'] as String? ?? 'classic',
    );
  }

  void update(void Function(AppSettings s) fn) {
    fn(this);
    notifyListeners();
  }
}

class SettingsStore {
  static const _key = 'popit.settings.v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._store, this.settings) {
    settings.addListener(_forward);
  }

  final SettingsStore _store;
  final AppSettings settings;

  void _forward() {
    notifyListeners();
    _store.save(settings);
  }

  @override
  void dispose() {
    settings.removeListener(_forward);
    super.dispose();
  }
}
