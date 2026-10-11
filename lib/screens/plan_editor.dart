import 'package:flutter/material.dart';

import '../data/workout_store.dart';
import '../models.dart';
import 'common.dart';
import 'exercise_picker.dart';

class PlanEditor extends StatefulWidget {
  const PlanEditor({super.key, required this.store, this.plan});
  final WorkoutStore store;
  final WorkoutPlan? plan;
  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final List<PlanEntry> _entries;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.plan?.name);
    _entries = [...?widget.plan?.entries];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePicker(
          store: widget.store,
          excluded: _entries.map((e) => e.exercise.id).toSet(),
        ),
      ),
    );
    if (exercise != null && mounted) {
      setState(() => _entries.add(PlanEntry(exercise)));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    if (_entries.isEmpty) {
      showError(context, ArgumentError('Add at least one exercise.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.store.savePlan(_name.text, _entries, id: widget.plan?.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, error);
      }
    }
  }

  void _target(int index, String value, bool sets) {
    final entry = _entries[index];
    _entries[index] = PlanEntry(
      entry.exercise,
      sets: sets ? int.tryParse(value) ?? 0 : entry.sets,
      reps: sets ? entry.reps : int.tryParse(value) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.plan == null ? 'Create plan' : 'Edit plan'),
    ),
    body: SafeArea(
      child: PageBody(
        child: Form(
          key: _form,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Plan name',
                    hintText: 'e.g. Upper body',
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Enter a plan name' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Exercises',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _saving ? null : _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Add exercise'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _entries.isEmpty
                    ? const EmptyState(
                        icon: Icons.fitness_center,
                        title: 'Build your routine',
                        message: 'Add exercises in the order you want to perform them.',
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        itemCount: _entries.length,
                        onReorderItem: (oldIndex, newIndex) => setState(() {
                          _entries.insert(
                            newIndex,
                            _entries.removeAt(oldIndex),
                          );
                        }),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Padding(
                            key: ValueKey(entry.exercise.id),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Tooltip(
                                          message: 'Drag to reorder',
                                          child: Icon(Icons.drag_handle),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.exercise.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip:
                                          'Options for ${entry.exercise.name}',
                                      onSelected: (action) => setState(() {
                                        if (action == 'remove') {
                                          _entries.removeAt(index);
                                        } else {
                                          final destination = action == 'up'
                                              ? index - 1
                                              : index + 1;
                                          _entries.insert(
                                            destination,
                                            _entries.removeAt(index),
                                          );
                                        }
                                      }),
                                      itemBuilder: (_) => [
                                        if (index > 0)
                                          const PopupMenuItem(
                                            value: 'up',
                                            child: Text('Move up'),
                                          ),
                                        if (index < _entries.length - 1)
                                          const PopupMenuItem(
                                            value: 'down',
                                            child: Text('Move down'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove exercise'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: '${entry.sets}',
                                        decoration: const InputDecoration(
                                          labelText: 'Target sets',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) =>
                                            _target(index, value, true),
                                        validator: positiveInteger,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: '${entry.reps}',
                                        decoration: const InputDecoration(
                                          labelText: 'Target reps',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) =>
                                            _target(index, value, false),
                                        validator: positiveInteger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save plan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String? positiveInteger(String? value) =>
    (int.tryParse(value ?? '') ?? 0) > 0 ? null : 'Enter a positive number';
