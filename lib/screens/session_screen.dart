import 'package:flutter/material.dart';

import '../data/workout_store.dart';
import '../models.dart';
import 'common.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.store,
    required this.sessionId,
    this.review = false,
  });
  final WorkoutStore store;
  final int sessionId;
  final bool review;
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late Future<WorkoutSession> _session;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _session = widget.store.session(widget.sessionId);
  }

  Future<void> _exercise(int index, WorkoutSession session) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SetLogger(
          store: widget.store,
          sessionId: widget.sessionId,
          exerciseIndex: index,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _review() async {
    final closed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SessionScreen(
          store: widget.store,
          sessionId: widget.sessionId,
          review: true,
        ),
      ),
    );
    if (!mounted) return;
    if (closed == true) {
      Navigator.pop(context);
    } else {
      setState(_reload);
    }
  }

  Future<void> _date(WorkoutSession workout) async {
    final date = await pickWorkoutDate(context, workout.date);
    if (date == null) return;
    try {
      await widget.store.setDate(workout.id, date);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Future<void> _finish(WorkoutSession workout) async {
    final unfinished = workout.exercises
        .where((e) => !e.skipped && e.done.length < e.sets.length)
        .length;
    if (unfinished > 0 &&
        !await confirm(
          context,
          'Finish with incomplete exercises?',
          'Only completed sets will count in your history and statistics.',
          action: 'Finish workout',
        )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.store.finishSession(workout.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, error);
      }
    }
  }

  Future<void> _delete(WorkoutSession workout) async {
    if (!await confirm(
      context,
      workout.completed ? 'Delete workout?' : 'Discard workout?',
      'This removes the session and all of its sets. Your workout plan is kept.',
      action: workout.completed ? 'Delete' : 'Discard',
    )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.store.deleteSession(workout.id);
      if (mounted) Navigator.pop(context, widget.review ? true : null);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkoutSession>(
    future: _session,
    builder: (context, snapshot) {
      final workout = snapshot.data;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.review || workout?.completed == true
                ? 'Workout summary'
                : 'Workout',
          ),
          actions: [
            if (workout != null)
              IconButton(
                tooltip: workout.completed
                    ? 'Delete workout'
                    : 'Discard workout',
                onPressed: _busy ? null : () => _delete(workout),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SafeArea(
          child: PageBody(
            child: snapshot.hasError
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load workout',
                    message: 'Please try again.',
                    action: OutlinedButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Retry'),
                    ),
                  )
                : workout == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          if (workout.completed)
                            const Icon(Icons.check_circle_outline),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy ? null : () => _date(workout),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(displayDate(context, workout.date)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (workout.completed || widget.review)
                        Text(
                          '${workout.setCount} completed sets · ${workout.repCount} reps',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      if (workout.completed || widget.review)
                        const SizedBox(height: 4),
                      if (workout.completed || widget.review)
                        Text(
                          '${number(workout.volume)} kg·reps of external load',
                        ),
                      if (!workout.completed && !widget.review) ...[
                        Text(
                          '${workout.exercises.where((e) => !e.skipped && e.sets.isNotEmpty && e.done.length == e.sets.length).length} of ${workout.exercises.length} exercises complete',
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: '${workout.setCount} completed sets',
                          child: LinearProgressIndicator(
                            value:
                                workout.exercises.fold<int>(
                                      0,
                                      (n, e) => n + e.sets.length,
                                    ) ==
                                    0
                                ? 0
                                : workout.setCount /
                                      workout.exercises.fold<int>(
                                        0,
                                        (n, e) => n + e.sets.length,
                                      ),
                            color: Theme.of(context).colorScheme.secondary,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Choose any exercise'),
                      ],
                      const SizedBox(height: 20),
                      ...workout.exercises.asMap().entries.map((entry) {
                        final e = entry.value;
                        final done = e.done.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: _ExerciseStatus(exercise: e),
                                  title: Text(
                                    e.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 20,
                                        ),
                                  ),
                                  subtitle: Text(
                                    e.skipped
                                        ? 'Skipped'
                                        : done == 0
                                        ? 'Ready to start'
                                        : '$done of ${e.sets.length} sets complete',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _busy
                                      ? null
                                      : () => _exercise(entry.key, workout),
                                ),
                                if (done > 0 &&
                                    (workout.completed || widget.review))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 64,
                                      right: 16,
                                      bottom: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: e.done
                                          .map(
                                            (s) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '${number(s.weight!)} kg × ${s.reps} reps',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      if (!workout.completed && !widget.review)
                        FilledButton.icon(
                          onPressed: _busy ? null : _review,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Review workout'),
                        )
                      else if (!workout.completed)
                        FilledButton.icon(
                          onPressed: _busy ? null : () => _finish(workout),
                          icon: const Icon(Icons.check),
                          label: Text(_busy ? 'Saving…' : 'Finish workout'),
                        )
                      else
                        Text(
                          'Tap an exercise to correct its sets. Changes update your statistics.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (!workout.completed && !widget.review) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${workout.exercises.where((e) => !e.skipped && e.sets.isNotEmpty && e.done.length == e.sets.length).length} of ${workout.exercises.length} exercises complete · ${workout.setCount} of ${workout.exercises.fold<int>(0, (n, e) => n + e.sets.length)} sets',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

class SetLogger extends StatefulWidget {
  const SetLogger({
    super.key,
    required this.store,
    required this.sessionId,
    required this.exerciseIndex,
  });
  final WorkoutStore store;
  final int sessionId, exerciseIndex;
  @override
  State<SetLogger> createState() => _SetLoggerState();
}

class _SetLoggerState extends State<SetLogger> {
  WorkoutSession? _session;
  SessionExercise? _previous;
  Object? _loadError;
  late int _index;
  Future<void> _pending = Future.value();
  final Map<int, (double?, int?, bool)> _failed = {};
  int _writes = 0;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _index = widget.exerciseIndex;
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await widget.store.session(widget.sessionId);
      final previous = await widget.store.previousExercise(
        session.exercises[_index].exerciseId,
        session.id,
      );
      if (mounted) {
        setState(() {
          _session = session;
          _previous = previous;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _saveSet(int id, double? weight, int? reps, bool completed) {
    setState(() => _writes++);
    final job = _pending.then((_) async {
      try {
        await widget.store.saveSet(id, weight, reps, completed);
        _failed.remove(id);
      } catch (_) {
        _failed[id] = (weight, reps, completed);
        rethrow;
      } finally {
        if (mounted) setState(() => _writes--);
      }
    });
    _pending = job.catchError((Object _) {});
    return job;
  }

  Future<void> _flush() async {
    await _pending;
    for (final entry in _failed.entries.toList()) {
      final (weight, reps, complete) = entry.value;
      await _saveSet(entry.key, weight, reps, complete);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _flush();
      await action();
      await _load();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    try {
      await _flush();
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final e = session?.exercises[_index];
    return PopScope(
      canPop: _writes == 0 && _failed.isEmpty && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _leave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(session?.name ?? 'Log exercise')),
        body: SafeArea(
          child: PageBody(
            child: e == null
                ? _loadError != null
                      ? EmptyState(
                          icon: Icons.error_outline,
                          title: 'Could not load sets',
                          message: 'Please try again.',
                          action: OutlinedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        e.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(displayDate(context, session!.date)),
                      const SizedBox(height: 16),
                      Text(
                        e.bodyweight
                            ? 'Enter 0 kg for bodyweight, or the added external load.'
                            : 'Record total load: include the bar; two 10 kg dumbbells = 20 kg.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (_previous != null) ...[
                        Material(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            title: Text(
                              'Last time: ${_previous!.done.map((s) => '${number(s.weight!)} kg × ${s.reps}').join(' · ')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            children: [
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () async {
                                        if (!await confirm(
                                          context,
                                          'Copy previous sets?',
                                          'This replaces the current set inputs. Copied sets remain unchecked.',
                                          action: 'Copy sets',
                                        )) {
                                          return;
                                        }
                                        await _action(() async {
                                          await widget.store.copySets(
                                            e.id,
                                            _previous!,
                                          );
                                          _session = null;
                                        });
                                      },
                                child: const Text('Copy previous sets'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (e.skipped)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'This exercise is skipped. Resume it to include its sets.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 56),
                            Expanded(
                              child: Text('KG', textAlign: TextAlign.center),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('REPS', textAlign: TextAlign.center),
                            ),
                            SizedBox(width: 56),
                          ],
                        ),
                      ),
                      ...e.sets.asMap().entries.map(
                        (entry) => SetInputRow(
                          key: ValueKey('${e.id}-${entry.value.id}'),
                          set: entry.value,
                          number: entry.key + 1,
                          disabled: _busy || e.skipped,
                          onSave: (weight, reps, complete) =>
                              _saveSet(entry.value.id, weight, reps, complete),
                          onDelete: () async {
                            if (!await confirm(
                              context,
                              'Remove set ${entry.key + 1}?',
                              'This set will be removed from the workout.',
                            )) {
                              return;
                            }
                            await _action(
                              () => widget.store.deleteSet(entry.value.id),
                            );
                          },
                        ),
                      ),
                      if (_failed.isNotEmpty) ...[
                        Text(
                          'Some changes could not be saved. Retry before leaving.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _busy ? null : () => _action(() async {}),
                          child: const Text('Retry saving'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        onPressed: _busy || e.skipped
                            ? null
                            : () => _action(() => widget.store.addSet(e.id)),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add set'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        icon: Icon(
                          e.skipped
                              ? Icons.play_arrow_outlined
                              : Icons.skip_next_outlined,
                        ),
                        onPressed: _busy
                            ? null
                            : () => _action(
                                () =>
                                    widget.store.skipExercise(e.id, !e.skipped),
                              ),
                        label: Text(
                          e.skipped ? 'Resume exercise' : 'Skip exercise',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            _failed.isEmpty
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _writes > 0
                                  ? 'Saving…'
                                  : _failed.isEmpty
                                  ? 'Valid entries saved on this device'
                                  : 'Save failed',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _leave,
                        child: const Text('Back to workout'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseStatus extends StatelessWidget {
  const _ExerciseStatus({required this.exercise});
  final SessionExercise exercise;
  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final colors = Theme.of(context).colorScheme;
    if (e.skipped) {
      return Icon(
        Icons.skip_next_outlined,
        color: colors.onSurfaceVariant,
        size: 32,
      );
    }
    if (e.done.isEmpty) {
      return Icon(
        Icons.radio_button_unchecked,
        color: colors.primary,
        size: 32,
      );
    }
    if (e.done.length == e.sets.length) {
      return Icon(Icons.check_circle, color: colors.primary, size: 32);
    }
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        value: e.done.length / e.sets.length,
        strokeWidth: 3,
        color: colors.secondary,
        backgroundColor: colors.primaryContainer,
        semanticsLabel: '${e.done.length} of ${e.sets.length} sets complete',
      ),
    );
  }
}

class SetInputRow extends StatefulWidget {
  const SetInputRow({
    super.key,
    required this.set,
    required this.number,
    required this.disabled,
    required this.onSave,
    required this.onDelete,
  });
  final LoggedSet set;
  final int number;
  final bool disabled;
  final Future<void> Function(double?, int?, bool) onSave;
  final VoidCallback onDelete;
  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late final TextEditingController _weight, _reps;
  late bool _complete;
  bool _checking = false;
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: widget.set.weight == null ? '' : number(widget.set.weight!),
    );
    _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
    _complete = widget.set.completed;
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  double? get _kg => double.tryParse(_weight.text.replaceAll(',', '.'));
  int? get _repCount => int.tryParse(_reps.text);
  bool get _valid =>
      _kg != null &&
      _kg!.isFinite &&
      _kg! >= 0 &&
      _repCount != null &&
      _repCount! > 0;
  Future<void> _save({bool? completed}) async {
    final complete = (completed ?? _complete) && _valid;
    try {
      await widget.onSave(
        _kg != null && _kg!.isFinite && _kg! >= 0 ? _kg : null,
        (_repCount ?? 0) > 0 ? _repCount : null,
        complete,
      );
      if (mounted) setState(() => _complete = complete);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 56,
                child: PopupMenuButton<String>(
                  enabled: !widget.disabled,
                  tooltip: 'Options for set ${widget.number}',
                  onSelected: (_) => widget.onDelete(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove set ${widget.number}'),
                    ),
                  ],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set ${widget.number}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Icon(Icons.more_horiz, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  enabled: !widget.disabled,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) => _kg != null && _kg!.isFinite && _kg! >= 0
                      ? null
                      : '0 kg or more',
                  onChanged: (_) => _save(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _reps,
                  enabled: !widget.disabled,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) =>
                      (_repCount ?? 0) > 0 ? null : 'At least 1 rep',
                  onChanged: (_) => _save(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 56,
                child: Checkbox(
                  semanticLabel: 'Complete set ${widget.number}',
                  value: _complete,
                  onChanged: widget.disabled || _checking
                      ? null
                      : (value) async {
                          if (value! && !_form.currentState!.validate()) return;
                          setState(() => _checking = true);
                          await _save(completed: value);
                          if (mounted) setState(() => _checking = false);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
