import 'dart:convert';

import 'package:flutter/services.dart';

import 'chart_library.dart';
import 'models.dart';

export 'chart_library.dart';

Future<Chart> loadDemoChart() async {
  final library = await ChartLibrary.load();
  return loadChart(library.defaultChart);
}

Future<Map<String, dynamic>> loadChartJson(String asset) async {
  final raw = await rootBundle.loadString(asset);
  return jsonDecode(raw) as Map<String, dynamic>;
}
