import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

Future<Chart> loadDemoChart() async {
  final raw = await rootBundle.loadString('assets/charts/demo.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final noteMaps = data['notes'] as List<dynamic>;
  final notes = <Note>[
    for (var i = 0; i < noteMaps.length; i++)
      Note.fromJson(noteMaps[i] as Map<String, dynamic>, i),
  ];

  return Chart(
    title: data['title'] as String? ?? 'Demo Beat',
    audioAsset: data['audioAsset'] as String,
    durationMs: data['durationMs'] as int,
    notes: notes,
  );
}
