import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import 'common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.sessions});
  final List<WorkoutSession> sessions;
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _exerciseId;
  String _range = 'Last 3 months', _metric = 'Weight';
  double _value(ProgressPoint point) => switch (_metric) {
    'Reps' => point.exercise.repCount.toDouble(),
    'Sets' => point.exercise.done.length.toDouble(),
    'Volume' => point.exercise.volume,
    _ => point.exercise.heaviest,
  };
  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.insights,
        title: 'See your progress take shape',
        message: 'Complete a workout to start tracking weight, reps, sets and training volume.',
      );
    }
    final exerciseNames = <int, String>{};
    for (final workout in widget.sessions) {
      for (final exercise in workout.exercises.where(
        (e) => e.done.isNotEmpty,
      )) {
        exerciseNames.putIfAbsent(exercise.exerciseId, () => exercise.name);
      }
    }
    if (exerciseNames.isEmpty) {
      return const EmptyState(
        icon: Icons.insights,
        title: 'No completed sets',
        message: 'Complete a set in a saved workout to see its progress.',
      );
    }
    final selectedId = exerciseNames.containsKey(_exerciseId)
        ? _exerciseId!
        : exerciseNames.keys.first;
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final sessions = widget.sessions
        .where(
          (s) =>
              _range == 'All time' ||
              !s.date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day)),
        )
        .toList();
    final points = exerciseProgress(sessions, selectedId);
    final allPoints = exerciseProgress(widget.sessions, selectedId);
    final bodyweight = allPoints.last.exercise.bodyweight;
    if (bodyweight && (_metric == 'Weight' || _metric == 'Volume')) {
      _metric = 'Reps';
    }
    final totalSets = sessions.fold<int>(0, (n, s) => n + s.setCount);
    final volume = sessions.fold<double>(0, (n, s) => n + s.volume);
    final weeks = <DateTime, int>{};
    for (final s in sessions) {
      final week = s.date.subtract(Duration(days: s.date.weekday - 1));
      weeks.update(week, (n) => n + 1, ifAbsent: () => 1);
    }
    final best = points.fold<double>(
      0,
      (n, p) => _value(p) > n ? _value(p) : n,
    );
    final unit = switch (_metric) {
      'Weight' => 'kg',
      'Volume' => 'kg·reps',
      'Sets' => 'sets',
      _ => 'reps',
    };
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your progress',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _range,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Date range'),
          items: [
            'Last 3 months',
            'All time',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => setState(() => _range = value!),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _Total(label: 'Workouts', value: '${sessions.length}'),
            _Total(label: 'Completed sets', value: '$totalSets'),
            _Total(
              label: 'Training volume',
              value: '${number(volume)} kg·reps',
            ),
          ],
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          key: ValueKey('exercise-$selectedId'),
          initialValue: selectedId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Exercise'),
          items: exerciseNames.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _exerciseId = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              (bodyweight
                      ? ['Reps', 'Sets']
                      : ['Weight', 'Reps', 'Sets', 'Volume'])
                  .map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: s == _metric,
                      labelStyle: TextStyle(
                        color: s == _metric
                            ? colors.onPrimary
                            : colors.onSurface,
                      ),
                      onSelected: (_) => setState(() => _metric = s),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          bodyweight
              ? 'Bodyweight progress uses reps and sets. Added kg measures external load only.'
              : 'Volume sums kg × reps for completed sets. Compare the same exercise and equipment.',
        ),
        const SizedBox(height: 20),
        if (points.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No sessions for this exercise in the selected date range. Try All time.',
            ),
          )
        else ...[
          Text(
            '${number(best)} $unit',
            style: Theme.of(context).textTheme.headlineLarge!
                .copyWith(color: colors.onSurface),
          ),
          const Text('Best in this range'),
          if (points.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Latest change: ${_value(points.last) - _value(points[points.length - 2]) >= 0 ? '+' : ''}'
                '${number(_value(points.last) - _value(points[points.length - 2]))} $unit vs previous session.',
              ),
            ),
          const SizedBox(height: 24),
          Semantics(
            label:
                '$_metric progress chart, ${points.length} sessions. Exact values are listed below.',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: points.length == 1 ? 1 : (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: best == 0 ? 1 : best * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, _) => Text(
                          number(value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      color: colors.secondary,
                      barWidth: 3,
                      isCurved: false,
                      dotData: FlDotData(show: true),
                      spots: points
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), _value(e.value)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(displayDate(context, points.first.session.date)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayDate(context, points.last.session.date),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recorded sessions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...points.reversed.map(
            (p) => Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(displayDate(context, p.session.date)),
                  subtitle: Text(
                    '${p.exercise.done.length} sets · ${p.exercise.repCount} reps',
                  ),
                  trailing: Text('${number(_value(p))} $unit'),
                ),
                ...p.exercise.done.map(
                  (s) => Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${number(s.weight!)} kg × ${s.reps} reps'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Divider(),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Workouts per week'),
          children: (weeks.keys.toList()..sort((a, b) => b.compareTo(a)))
              .map(
                (week) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Week of ${displayDate(context, week)}'),
                  trailing: Text('${weeks[week]} workouts'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    ),
  );
}
