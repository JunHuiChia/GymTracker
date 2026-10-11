import 'package:flutter/material.dart';

import '../data/exercise_catalogue.dart';
import '../data/workout_store.dart';
import '../models.dart';
import 'common.dart';

class ExercisePicker extends StatefulWidget {
  const ExercisePicker({
    super.key,
    required this.store,
    this.excluded = const {},
  });
  final WorkoutStore store;
  final Set<int> excluded;
  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  late Future<List<Exercise>> _exercises;
  String _query = '', _muscle = 'All muscles', _equipment = 'All equipment';
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _exercises = widget.store.exercises();
  }

  Future<void> _edit([Exercise? exercise]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExerciseEditor(store: widget.store, exercise: exercise),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose exercise')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      icon: const Icon(Icons.add),
      label: const Text('Custom exercise'),
    ),
    body: SafeArea(
      child: PageBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search exercises',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          MediaQuery.textScalerOf(context).scale(14) > 16
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: DropdownButtonFormField<String>(
                              initialValue: _muscle,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Muscle group',
                              ),
                              items: ['All muscles', ...muscleGroups]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _muscle = value!),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: DropdownButtonFormField<String>(
                              initialValue: _equipment,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Equipment',
                              ),
                              items: ['All equipment', ...equipmentTypes]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _equipment = value!),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Exercise>>(
                future: _exercises,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load exercises',
                      message: 'Your saved data has not been changed.',
                      action: OutlinedButton(
                        onPressed: () => setState(_reload),
                        child: const Text('Retry'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final exercises = snapshot.data!
                      .where(
                        (e) =>
                            !widget.excluded.contains(e.id) &&
                            e.name.toLowerCase().contains(
                              _query.trim().toLowerCase(),
                            ) &&
                            (_muscle == 'All muscles' || e.muscle == _muscle) &&
                            (_equipment == 'All equipment' ||
                                e.equipment == _equipment),
                      )
                      .toList();
                  if (exercises.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching exercises',
                      message:
                          'Try a different search or add your own exercise.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: exercises.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = exercises[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        title: Text(e.name),
                        subtitle: Text('${e.muscle} · ${e.equipment}'),
                        onTap: () => Navigator.pop(context, e),
                        trailing: e.builtIn
                            ? const Icon(Icons.add)
                            : PopupMenuButton<String>(
                                tooltip: 'Custom exercise options',
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await _edit(e);
                                    return;
                                  }
                                  if (!await confirm(
                                    context,
                                    'Archive ${e.name}?',
                                    'It will be hidden from new selections. Existing plans and workout history are kept.',
                                    action: 'Archive',
                                  )) {
                                    return;
                                  }
                                  try {
                                    await widget.store.archiveExercise(e.id);
                                    if (mounted) setState(_reload);
                                  } catch (error) {
                                    if (context.mounted) {
                                      showError(context, error);
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text('Archive'),
                                  ),
                                ],
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExerciseEditor extends StatefulWidget {
  const ExerciseEditor({super.key, required this.store, this.exercise});
  final WorkoutStore store;
  final Exercise? exercise;
  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _muscle, _equipment;
  late bool _bodyweight;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.exercise?.name);
    _muscle = widget.exercise?.muscle ?? 'Other';
    _equipment = widget.exercise?.equipment ?? 'Other';
    _bodyweight = widget.exercise?.bodyweight ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.store.saveExercise(
        id: widget.exercise?.id,
        name: _name.text,
        muscle: _muscle,
        equipment: _equipment,
        bodyweight: _bodyweight,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.exercise == null ? 'Custom exercise' : 'Edit exercise',
      ),
    ),
    body: SafeArea(
      child: PageBody(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Exercise name'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Enter an exercise name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _muscle,
                decoration: const InputDecoration(labelText: 'Muscle group'),
                items: muscleGroups
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => _muscle = value!,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _equipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                items: equipmentTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => _equipment = value!,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bodyweight exercise'),
                subtitle: const Text('Track reps and any added external load.'),
                value: _bodyweight,
                onChanged: (value) => setState(() => _bodyweight = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save exercise'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
