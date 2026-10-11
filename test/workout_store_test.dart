import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/workout_store.dart';
import 'package:gym_tracker/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late WorkoutStore store;
  setUp(
    () async => store = await WorkoutStore.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    ),
  );
  tearDown(() async => store.database.close());
  Future<WorkoutPlan> plan() async {
    final exercise = (await store.exercises()).firstWhere(
      (e) => e.name == 'Barbell bench press',
    );
    await store.savePlan('Upper body', [PlanEntry(exercise)]);
    return (await store.plans()).single;
  }

  test('catalogue has stable IDs and custom exercises are separate', () async {
    final original = await store.exercises();
    expect(original.length, 35);
    await store.saveExercise(
      name: 'My machine row',
      muscle: 'Back',
      equipment: 'Machine',
      bodyweight: false,
    );
    final custom = (await store.exercises()).singleWhere((e) => !e.builtIn);
    expect(custom.id, greaterThan(35));
    expect(
      (await store.exercises()).where((e) => e.builtIn).map((e) => e.id),
      original.map((e) => e.id),
    );
    await expectLater(
      store.archiveExercise(original.first.id),
      throwsStateError,
    );
  });

  test('plan edits and archival preserve session snapshots', () async {
    final template = await plan();
    final id = await store.startSession(template, DateTime(2026, 10, 10));
    await store.savePlan('Changed', [
      PlanEntry(template.entries.single.exercise, sets: 1, reps: 5),
    ], id: template.id);
    await store.archivePlan(template.id);
    final workout = await store.session(id);
    expect(workout.name, 'Upper body');
    expect(workout.exercises.single.sets.length, 3);
    expect(workout.exercises.single.sets.first.reps, 10);
    expect(await store.plans(), isEmpty);
    await expectLater(
      store.startSession(template, DateTime.now()),
      throwsStateError,
    );
  });

  test(
    'variable sets produce exact totals and draft sets are excluded',
    () async {
      final id = await store.startSession(await plan(), DateTime(2026, 10, 10));
      var workout = await store.session(id);
      final sets = workout.exercises.single.sets;
      await store.saveSet(sets[0].id, 50, 10, true);
      await store.saveSet(sets[1].id, 50, 8, true);
      await store.saveSet(sets[2].id, 45, 12, false);
      expect(await store.history(), isEmpty);
      expect(
        exerciseProgress([
          await store.session(id),
        ], workout.exercises.single.exerciseId),
        isEmpty,
      );
      await store.saveSet(sets[2].id, 45, 12, true);
      await store.finishSession(id);
      workout = (await store.history()).single;
      expect(workout.setCount, 3);
      expect(workout.repCount, 30);
      expect(workout.volume, 1440);
      await store.saveSet(sets[0].id, 55, 10, true);
      expect((await store.history()).single.volume, 1490);
      await store.skipExercise(workout.exercises.single.id, true);
      expect((await store.history()).single.setCount, 0);
      expect(
        exerciseProgress(
          await store.history(),
          workout.exercises.single.exerciseId,
        ),
        isEmpty,
      );
    },
  );

  test('invalid set data rejected and bodyweight zero accepted', () async {
    final id = await store.startSession(await plan(), DateTime.now());
    final setId = (await store.session(id)).exercises.single.sets.first.id;
    await expectLater(store.finishSession(id), throwsStateError);
    await expectLater(
      store.saveSet(setId, double.nan, 10, true),
      throwsArgumentError,
    );
    await expectLater(store.saveSet(setId, -1, 10, true), throwsArgumentError);
    await expectLater(store.saveSet(setId, 50, 0, true), throwsArgumentError);
    await expectLater(
      store.saveSet(setId, null, 10, true),
      throwsArgumentError,
    );
    await store.saveSet(setId, 0, 10, true);
    await store.finishSession(id);
    expect((await store.history()).single.repCount, 10);
  });

  test('copied previous sets stay unchecked and deletion cascades', () async {
    final template = await plan();
    final first = await store.startSession(template, DateTime(2026, 10, 9));
    final e = (await store.session(first)).exercises.single;
    await store.saveSet(e.sets.first.id, 20, 12, true);
    await store.finishSession(first);
    final second = await store.startSession(template, DateTime(2026, 10, 10));
    final current = (await store.session(second)).exercises.single;
    await store.copySets(
      current.id,
      (await store.previousExercise(e.exerciseId, second))!,
    );
    final copied = (await store.session(second)).exercises.single.sets.single;
    expect(copied.weight, 20);
    expect(copied.reps, 12);
    expect(copied.completed, false);
    await store.deleteSession(second);
    expect(await store.activeId(), isNull);
    expect(
      await store.database.query(
        'logged_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [current.id],
      ),
      isEmpty,
    );
    expect(await store.history(), hasLength(1));
  });

  test('file database survives reopen without duplicate seeds', () async {
    final directory = await Directory.systemTemp.createTemp('gymtracker_test_');
    final location = '${directory.path}/test.db';
    var disk = await WorkoutStore.open(
      factory: databaseFactoryFfi,
      databasePath: location,
    );
    final exercise = (await disk.exercises()).first;
    await disk.savePlan('Persistent plan', [PlanEntry(exercise)]);
    final id = await disk.startSession(
      (await disk.plans()).single,
      DateTime(2026, 10, 10),
    );
    final set = (await disk.session(id)).exercises.single.sets.first;
    await disk.saveSet(set.id, 17.5, 8, false);
    await disk.database.close();
    disk = await WorkoutStore.open(
      factory: databaseFactoryFfi,
      databasePath: location,
    );
    expect(await disk.exercises(), hasLength(35));
    expect((await disk.plans()).single.name, 'Persistent plan');
    expect(await disk.activeId(), id);
    expect((await disk.session(id)).exercises.single.sets.first.weight, 17.5);
    await disk.database.close();
    await File(location).delete();
    await directory.delete();
  });

  test('same-day exercise progress keeps each session separately', () async {
    final template = await plan();
    for (final weight in [20.0, 25.0]) {
      final id = await store.startSession(template, DateTime(2026, 10, 10));
      final e = (await store.session(id)).exercises.single;
      await store.saveSet(e.sets.first.id, weight, 10, true);
      await store.finishSession(id);
    }
    final progress = exerciseProgress(
      await store.history(),
      template.entries.single.exercise.id,
    );
    expect(progress, hasLength(2));
    expect(progress.map((p) => p.exercise.heaviest), [20.0, 25.0]);
  });
}
