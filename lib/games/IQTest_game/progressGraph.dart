import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'iqGame_data.dart';

class ProgressGraphPage extends StatefulWidget {
  const ProgressGraphPage({super.key});

  @override
  State<ProgressGraphPage> createState() => _ProgressGraphPageState();
}

class _ProgressGraphPageState extends State<ProgressGraphPage> {
  Map<String, List<int>> sectionScores = {};

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<int>> scores = {};
    for (var section in sections) {
      final list = prefs.getStringList('scores_${section.title}') ?? [];
      scores[section.title] = list.map(int.parse).toList();
    }
    setState(() {
      sectionScores = scores;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (sectionScores.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress Graph')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Graph')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: sections.map((section) {
            final scores = sectionScores[section.title] ?? [];
            if (scores.isEmpty) {
              return ListTile(
                title: Text(section.title),
                subtitle: const Text('No data yet'),
              );
            }
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: const TextStyle(fontSize: 20)),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                scores.length,
                                    (i) => FlSpot(i.toDouble(), scores[i].toDouble()),
                              ),
                              isCurved: true,
                              color: Colors.deepPurple,
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          minY: 0,
                          maxY: 50,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, interval: 1),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, interval: 10),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}