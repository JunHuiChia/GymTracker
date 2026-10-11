import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/data/workout_store.dart';
import '../lib/models.dart';

void main() {
  test('create and verify a synthetic release upgrade record', () async {
    sqfliteFfiInit();
    final location = File('.impeccable/upgrade-fixture/gym_tracker.db').absolute.path;
    await Directory('.impeccable/upgrade-fixture').create(recursive: true);
    final store = await WorkoutStore.open(
      factory: databaseFactoryFfi,
      databasePath: location,
    );
    if (Platform.environment['VERIFY_UPGRADE'] != '1') {
      final exercise = (await store.exercises()).firstWhere(
        (e) => e.name == 'Barbell bench press',
      );
      await store.savePlan('Upgrade smoke test', [PlanEntry(exercise, sets: 1, reps: 8)]);
      final id = await store.startSession((await store.plans()).single, DateTime(2026, 10, 10));
      final workout = await store.session(id);
      await store.saveSet(workout.exercises.single.sets.single.id, 42.5, 8, true);
      await store.finishSession(id);
    }
    expect((await store.plans()).single.name, 'Upgrade smoke test');
    final history = (await store.history()).single;
    expect(history.volume, 340);
    expect(history.exercises.single.sets.single.weight, 42.5);
    expect(history.exercises.single.sets.single.reps, 8);
    await store.database.close();
  });
}
