import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'exercise_catalogue.dart';

class WorkoutStore {
  WorkoutStore._(this.database);
  final Database database;

  static Future<WorkoutStore> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final location =
        databasePath ??
        path.join(await dbFactory.getDatabasesPath(), 'gym_tracker.db');
    final db = await dbFactory.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            '''CREATE TABLE exercises (
          id INTEGER PRIMARY KEY, name TEXT NOT NULL CHECK(length(trim(name)) > 0),
          muscle TEXT NOT NULL, equipment TEXT NOT NULL, bodyweight INTEGER NOT NULL DEFAULT 0,
          built_in INTEGER NOT NULL DEFAULT 0, archived INTEGER NOT NULL DEFAULT 0)''',
          );
          await db.execute('''CREATE TABLE plans (
          id INTEGER PRIMARY KEY, name TEXT NOT NULL CHECK(length(trim(name)) > 0),
          archived INTEGER NOT NULL DEFAULT 0)''');
          await db.execute(
            '''CREATE TABLE plan_exercises (
          id INTEGER PRIMARY KEY, plan_id INTEGER NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
          exercise_id INTEGER NOT NULL REFERENCES exercises(id), position INTEGER NOT NULL,
          target_sets INTEGER NOT NULL CHECK(target_sets > 0),
          target_reps INTEGER NOT NULL CHECK(target_reps > 0), UNIQUE(plan_id, exercise_id))''',
          );
          await db.execute('''CREATE TABLE sessions (
          id INTEGER PRIMARY KEY, plan_id INTEGER REFERENCES plans(id), name TEXT NOT NULL,
          performed_date TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, completed_at TEXT)''');
          await db.execute(
            'CREATE UNIQUE INDEX one_active_workout ON sessions(completed) WHERE completed = 0',
          );
          await db.execute(
            '''CREATE TABLE session_exercises (
          id INTEGER PRIMARY KEY, session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
          exercise_id INTEGER NOT NULL REFERENCES exercises(id), name TEXT NOT NULL,
          bodyweight INTEGER NOT NULL, position INTEGER NOT NULL, skipped INTEGER NOT NULL DEFAULT 0)''',
          );
          await db.execute(
            '''CREATE TABLE logged_sets (
          id INTEGER PRIMARY KEY, session_exercise_id INTEGER NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
          position INTEGER NOT NULL, weight REAL CHECK(weight >= 0), reps INTEGER CHECK(reps > 0),
          completed INTEGER NOT NULL DEFAULT 0,
          CHECK(completed = 0 OR (weight IS NOT NULL AND reps IS NOT NULL)))''',
          );
          await db.execute(
            'CREATE INDEX session_exercise_lookup ON session_exercises(exercise_id, session_id)',
          );
          final batch = db.batch();
          for (var i = 0; i < exerciseCatalogue.length; i++) {
            final (name, muscle, equipment, bodyweight) = exerciseCatalogue[i];
            batch.insert('exercises', {
              'id': i + 1,
              'name': name,
              'muscle': muscle,
              'equipment': equipment,
              'bodyweight': bodyweight ? 1 : 0,
              'built_in': 1,
            });
          }
          await batch.commit(noResult: true);
        },
      ),
    );
    return WorkoutStore._(db);
  }

  Future<List<Exercise>> exercises() async => (await database.query(
    'exercises',
    where: 'archived = 0',
    orderBy: 'name COLLATE NOCASE',
  )).map(Exercise.fromMap).toList();

  Future<void> saveExercise({
    int? id,
    required String name,
    required String muscle,
    required String equipment,
    required bool bodyweight,
  }) async {
    if (name.trim().isEmpty ||
        !muscleGroups.contains(muscle) ||
        !equipmentTypes.contains(equipment)) {
      throw ArgumentError('Enter a name, muscle group and equipment.');
    }
    final values = {
      'name': name.trim(),
      'muscle': muscle,
      'equipment': equipment,
      'bodyweight': bodyweight ? 1 : 0,
    };
    if (id == null) {
      await database.insert('exercises', values);
    } else {
      final count = await database.update(
        'exercises',
        values,
        where: 'id = ? AND built_in = 0',
        whereArgs: [id],
      );
      if (count != 1) throw StateError('Built-in exercises cannot be edited.');
    }
  }

  Future<void> archiveExercise(int id) async {
    final count = await database.update(
      'exercises',
      {'archived': 1},
      where: 'id = ? AND built_in = 0',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Only custom exercises can be archived.');
  }

  Future<List<WorkoutPlan>> plans() async {
    final rows = await database.query(
      'plans',
      where: 'archived = 0',
      orderBy: 'id DESC',
    );
    final result = <WorkoutPlan>[];
    for (final row in rows) {
      final entries = await database.rawQuery(
        '''SELECT e.*, pe.target_sets, pe.target_reps
        FROM plan_exercises pe JOIN exercises e ON e.id = pe.exercise_id
        WHERE pe.plan_id = ? ORDER BY pe.position''',
        [row['id']],
      );
      result.add(
        WorkoutPlan(
          row['id'] as int,
          row['name'] as String,
          entries
              .map(
                (e) => PlanEntry(
                  Exercise.fromMap(e),
                  sets: e['target_sets'] as int,
                  reps: e['target_reps'] as int,
                ),
              )
              .toList(),
        ),
      );
    }
    return result;
  }

  Future<int> savePlan(String name, List<PlanEntry> entries, {int? id}) async {
    if (name.trim().isEmpty ||
        entries.isEmpty ||
        entries.any((e) => e.sets < 1 || e.reps < 1)) {
      throw ArgumentError(
        'Give the plan a name and at least one exercise with positive targets.',
      );
    }
    if (entries.map((e) => e.exercise.id).toSet().length != entries.length) {
      throw ArgumentError('Each exercise can appear once in a plan.');
    }
    return database.transaction((txn) async {
      final planId = id ?? await txn.insert('plans', {'name': name.trim()});
      if (id != null) {
        await txn.update(
          'plans',
          {'name': name.trim()},
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          'plan_exercises',
          where: 'plan_id = ?',
          whereArgs: [id],
        );
      }
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        await txn.insert('plan_exercises', {
          'plan_id': planId,
          'exercise_id': e.exercise.id,
          'position': i,
          'target_sets': e.sets,
          'target_reps': e.reps,
        });
      }
      return planId;
    });
  }

  Future<void> archivePlan(int id) async {
    await database.update(
      'plans',
      {'archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> activeId() async {
    final rows = await database.query(
      'sessions',
      columns: ['id'],
      where: 'completed = 0',
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<int> startSession(WorkoutPlan plan, DateTime date) async {
    if (plan.entries.isEmpty) {
      throw ArgumentError('Add an exercise to this plan first.');
    }
    return database.transaction((txn) async {
      if ((await txn.query('sessions', where: 'completed = 0')).isNotEmpty) {
        throw StateError(
          'Resume or discard the current workout before starting another.',
        );
      }
      final id = await txn.insert('sessions', {
        'plan_id': plan.id,
        'name': plan.name,
        'performed_date': dateKey(date),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      for (var i = 0; i < plan.entries.length; i++) {
        final entry = plan.entries[i];
        final exerciseId = await txn.insert('session_exercises', {
          'session_id': id,
          'exercise_id': entry.exercise.id,
          'name': entry.exercise.name,
          'bodyweight': entry.exercise.bodyweight ? 1 : 0,
          'position': i,
        });
        for (var set = 0; set < entry.sets; set++) {
          await txn.insert('logged_sets', {
            'session_exercise_id': exerciseId,
            'position': set,
            'reps': entry.reps,
            'weight': entry.exercise.bodyweight ? 0.0 : null,
          });
        }
      }
      return id;
    });
  }

  Future<WorkoutSession> session(int id) async {
    final header = (await database.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    )).single;
    final rows = await database.query(
      'session_exercises',
      where: 'session_id = ?',
      whereArgs: [id],
      orderBy: 'position',
    );
    final entries = <SessionExercise>[];
    for (final row in rows) {
      final sets = await database.query(
        'logged_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position, id',
      );
      entries.add(
        SessionExercise(
          row['id'] as int,
          row['exercise_id'] as int,
          row['name'] as String,
          row['bodyweight'] == 1,
          row['skipped'] == 1,
          sets
              .map(
                (s) => LoggedSet(
                  s['id'] as int,
                  s['position'] as int,
                  (s['weight'] as num?)?.toDouble(),
                  s['reps'] as int?,
                  s['completed'] == 1,
                ),
              )
              .toList(),
        ),
      );
    }
    return WorkoutSession(
      id,
      header['name'] as String,
      DateTime.parse(header['performed_date'] as String),
      header['completed'] == 1,
      entries,
    );
  }

  Future<List<WorkoutSession>> history() async {
    final rows = await database.query(
      'sessions',
      where: 'completed = 1',
      orderBy: 'performed_date DESC, id DESC',
    );
    final exerciseRows = await database.rawQuery(
      '''SELECT e.* FROM session_exercises e
      JOIN sessions s ON s.id = e.session_id WHERE s.completed = 1 ORDER BY e.position''',
    );
    final setRows = await database.rawQuery(
      '''SELECT l.* FROM logged_sets l
      JOIN session_exercises e ON e.id = l.session_exercise_id
      JOIN sessions s ON s.id = e.session_id WHERE s.completed = 1 ORDER BY l.position, l.id''',
    );
    final sets = <int, List<LoggedSet>>{};
    for (final row in setRows) {
      sets
          .putIfAbsent(row['session_exercise_id'] as int, () => [])
          .add(
            LoggedSet(
              row['id'] as int,
              row['position'] as int,
              (row['weight'] as num?)?.toDouble(),
              row['reps'] as int?,
              row['completed'] == 1,
            ),
          );
    }
    final exercises = <int, List<SessionExercise>>{};
    for (final row in exerciseRows) {
      exercises
          .putIfAbsent(row['session_id'] as int, () => [])
          .add(
            SessionExercise(
              row['id'] as int,
              row['exercise_id'] as int,
              row['name'] as String,
              row['bodyweight'] == 1,
              row['skipped'] == 1,
              sets[row['id']] ?? [],
            ),
          );
    }
    return rows
        .map(
          (row) => WorkoutSession(
            row['id'] as int,
            row['name'] as String,
            DateTime.parse(row['performed_date'] as String),
            true,
            exercises[row['id']] ?? [],
          ),
        )
        .toList();
  }

  Future<void> setDate(int id, DateTime date) async {
    await database.update(
      'sessions',
      {'performed_date': dateKey(date)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveSet(
    int id,
    double? weight,
    int? reps,
    bool completed,
  ) async {
    if ((weight != null && (!weight.isFinite || weight < 0)) ||
        (reps != null && reps < 1) ||
        (completed && (weight == null || reps == null))) {
      throw ArgumentError('Enter a weight of 0 kg or more and at least 1 rep.');
    }
    await database.update(
      'logged_sets',
      {'weight': weight, 'reps': reps, 'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addSet(int exerciseId) async {
    await database.transaction((txn) async {
      final rows = await txn.query(
        'logged_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'position DESC',
        limit: 1,
      );
      await txn.insert('logged_sets', {
        'session_exercise_id': exerciseId,
        'position': rows.isEmpty ? 0 : (rows.first['position'] as int) + 1,
      });
    });
  }

  Future<void> deleteSet(int id) async {
    await database.delete('logged_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> skipExercise(int id, bool skipped) async {
    await database.update(
      'session_exercises',
      {'skipped': skipped ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> finishSession(int id) async {
    final workout = await session(id);
    if (workout.setCount == 0) {
      throw StateError('Complete at least one set before finishing.');
    }
    await database.update(
      'sessions',
      {
        'completed': 1,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(int id) async {
    await database.transaction((txn) async {
      await txn.delete('sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<SessionExercise?> previousExercise(
    int exerciseId,
    int currentSession,
  ) async {
    final historyItems = await history();
    for (final workout in historyItems) {
      if (workout.id == currentSession) continue;
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId && exercise.done.isNotEmpty) {
          return exercise;
        }
      }
    }
    return null;
  }

  Future<void> copySets(int targetId, SessionExercise previous) async {
    await database.transaction((txn) async {
      await txn.delete(
        'logged_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [targetId],
      );
      var position = 0;
      for (final set in previous.done) {
        await txn.insert('logged_sets', {
          'session_exercise_id': targetId,
          'position': position++,
          'weight': set.weight,
          'reps': set.reps,
        });
      }
    });
  }
}
