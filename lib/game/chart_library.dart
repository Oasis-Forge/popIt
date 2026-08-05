import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

class ChartMeta {
  const ChartMeta({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.durationMs,
    required this.audioAsset,
    required this.chartAsset,
  });

  final String id;
  final String title;
  final String artist;
  final int bpm;
  final int durationMs;
  final String audioAsset;
  final String chartAsset;

  factory ChartMeta.fromJson(Map<String, dynamic> json) => ChartMeta(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String? ?? 'Unknown',
        bpm: json['bpm'] as int? ?? 120,
        durationMs: json['durationMs'] as int,
        audioAsset: json['audioAsset'] as String,
        chartAsset: json['chartAsset'] as String,
      );
}

class ChartLibrary {
  ChartLibrary(this.charts);

  final List<ChartMeta> charts;

  /// Tracks offered in pickers / Daily (excludes coach).
  List<ChartMeta> get songCharts =>
      charts.where((c) => c.id != 'coach_intro').toList();

  ChartMeta get defaultChart =>
      songCharts.isNotEmpty ? songCharts.first : charts.first;

  ChartMeta byId(String id) =>
      charts.firstWhere((c) => c.id == id, orElse: () => defaultChart);

  static Future<ChartLibrary> load() async {
    final raw = await rootBundle.loadString('assets/charts/manifest.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = (data['charts'] as List<dynamic>)
        .map((e) => ChartMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return ChartLibrary(list);
  }
}

Chart parseChart(Map<String, dynamic> data, ChartMeta meta) {
  final noteMaps = data['notes'] as List<dynamic>;
  final notes = <Note>[
    for (var i = 0; i < noteMaps.length; i++)
      Note.fromJson(noteMaps[i] as Map<String, dynamic>, i),
  ];
  return Chart(
    id: meta.id,
    title: data['title'] as String? ?? meta.title,
    artist: meta.artist,
    bpm: meta.bpm,
    audioAsset: data['audioAsset'] as String? ?? meta.audioAsset,
    durationMs: data['durationMs'] as int? ?? meta.durationMs,
    notes: notes,
  );
}

Future<Chart> loadChart(ChartMeta meta) async {
  final raw = await rootBundle.loadString(meta.chartAsset);
  return parseChart(jsonDecode(raw) as Map<String, dynamic>, meta);
}

@Deprecated('Use ChartLibrary + loadChart')
Future<Chart> loadDemoChart() async {
  final library = await ChartLibrary.load();
  return loadChart(library.defaultChart);
}
