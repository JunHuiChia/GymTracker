import 'package:flutter/material.dart';

import '../data/workout_store.dart';
import '../models.dart';
import 'common.dart';
import 'plan_editor.dart';
import 'session_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final WorkoutStore store;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late Future<(List<WorkoutPlan>, List<WorkoutSession>, WorkoutSession?)> _data;
  bool _starting = false;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _data = _load();
  }

  Future<(List<WorkoutPlan>, List<WorkoutSession>, WorkoutSession?)>
  _load() async {
    final plans = await widget.store.plans();
    final history = await widget.store.history();
    final active = await widget.store.activeId();
    return (
      plans,
      history,
      active == null ? null : await widget.store.session(active),
    );
  }

  Future<void> _edit([WorkoutPlan? plan]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlanEditor(store: widget.store, plan: plan),
      ),
    );
    if (mounted) setState(_refresh);
  }

  Future<void> _openSession(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(store: widget.store, sessionId: id),
      ),
    );
    if (mounted) setState(_refresh);
  }

  Future<void> _start(WorkoutPlan plan, WorkoutSession? active) async {
    if (_starting) return;
    if (active != null) {
      await _openSession(active.id);
      return;
    }
    setState(() => _starting = true);
    try {
      final id = await widget.store.startSession(plan, DateTime.now());
      if (mounted) await _openSession(id);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final expanded = constraints.maxWidth >= 700;
      final destinations = const [
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: 'Workouts',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Stats',
        ),
      ];
      return Scaffold(
        appBar: AppBar(
          title: Text(['GymTracker', 'History', 'GymTracker'][_tab]),
          actions: [
            IconButton(
              tooltip: 'Refresh saved workouts',
              onPressed: () => setState(_refresh),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: expanded
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (value) => setState(() => _tab = value),
                destinations: destinations,
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (expanded)
                NavigationRail(
                  selectedIndex: _tab,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (value) =>
                      setState(() => _tab = value),
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: PageBody(
                  child:
                      FutureBuilder<
                        (
                          List<WorkoutPlan>,
                          List<WorkoutSession>,
                          WorkoutSession?,
                        )
                      >(
                        future: _data,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return EmptyState(
                              icon: Icons.error_outline,
                              title: 'Could not load workouts',
                              message: 'Your data has not been reset.',
                              action: OutlinedButton(
                                onPressed: () => setState(_refresh),
                                child: const Text('Retry'),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final (plans, history, active) = snapshot.data!;
                          if (_tab == 2) return StatsScreen(sessions: history);
                          if (_tab == 1) {
                            if (history.isEmpty) {
                              return const EmptyState(
                                icon: Icons.history,
                                title: 'Your training history starts here',
                                message: 'Finish a workout to see its date, exercises and sets.',
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: history.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final workout = history[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Text(workout.name),
                                  subtitle: Text(
                                    '${displayDate(context, workout.date)}\n'
                                    '${workout.setCount} sets · ${number(workout.volume)} kg·reps',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openSession(workout.id),
                                );
                              },
                            );
                          }
                          if (plans.isEmpty && active == null) {
                            return EmptyState(
                              icon: Icons.fitness_center,
                              title: 'A routine you can return to',
                              message: 'Create your first workout plan, then log each set as you train.',
                              action: FilledButton.icon(
                                onPressed: _edit,
                                icon: const Icon(Icons.add),
                                label: const Text('Create plan'),
                              ),
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            children: [
                              if (active != null) ...[
                                Material(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  child: ListTile(
                                    textColor: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                    iconColor: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: const Icon(
                                      Icons.play_circle_outline,
                                    ),
                                    title: Text(
                                      'Resume ${active.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                    ),
                                    subtitle: Text(
                                      '${displayDate(context, active.date)} · ${active.setCount} saved sets',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _openSession(active.id),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Your plans',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _edit,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create plan'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...plans.map(
                                (plan) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      plan.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${plan.entries.length} ${plan.entries.length == 1 ? 'exercise' : 'exercises'} · ${plan.entries.fold<int>(0, (n, e) => n + e.sets)} target sets',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              tooltip:
                                                  'Options for ${plan.name}',
                                              onSelected: (action) async {
                                                if (action == 'edit') {
                                                  await _edit(plan);
                                                  return;
                                                }
                                                if (!await confirm(
                                                  context,
                                                  'Archive ${plan.name}?',
                                                  'The plan is hidden. Past workouts and an active workout are kept.',
                                                  action: 'Archive',
                                                )) {
                                                  return;
                                                }
                                                try {
                                                  await widget.store
                                                      .archivePlan(plan.id);
                                                  if (mounted) {
                                                    setState(_refresh);
                                                  }
                                                } catch (error) {
                                                  if (context.mounted) {
                                                    showError(context, error);
                                                  }
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit plan'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'archive',
                                                  child: Text('Archive plan'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...plan.entries
                                            .take(3)
                                            .map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Text(
                                                  e.exercise.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ),
                                            ),
                                        if (plan.entries.length > 3)
                                          Text(
                                            '+ ${plan.entries.length - 3} more exercises',
                                          ),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          onPressed: _starting
                                              ? null
                                              : () => _start(plan, active),
                                          icon: const Icon(Icons.play_arrow),
                                          label: Text(
                                            active == null
                                                ? 'Start workout'
                                                : 'Resume active workout',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
