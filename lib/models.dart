class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.equipment,
    this.bodyweight = false,
    this.builtIn = false,
  });
  final int id;
  final String name, muscle, equipment;
  final bool bodyweight, builtIn;
  factory Exercise.fromMap(Map<String, Object?> row) => Exercise(
    id: row['id'] as int,
    name: row['name'] as String,
    muscle: row['muscle'] as String,
    equipment: row['equipment'] as String,
    bodyweight: row['bodyweight'] == 1,
    builtIn: row['built_in'] == 1,
  );
}

class PlanEntry {
  const PlanEntry(this.exercise, {this.sets = 3, this.reps = 10});
  final Exercise exercise;
  final int sets, reps;
}

class WorkoutPlan {
  const WorkoutPlan(this.id, this.name, this.entries);
  final int id;
  final String name;
  final List<PlanEntry> entries;
}

class LoggedSet {
  const LoggedSet(
    this.id,
    this.position,
    this.weight,
    this.reps,
    this.completed,
  );
  final int id, position;
  final double? weight;
  final int? reps;
  final bool completed;
  double get volume => completed ? (weight ?? 0) * (reps ?? 0) : 0;
}

class SessionExercise {
  const SessionExercise(
    this.id,
    this.exerciseId,
    this.name,
    this.bodyweight,
    this.skipped,
    this.sets,
  );
  final int id, exerciseId;
  final String name;
  final bool bodyweight, skipped;
  final List<LoggedSet> sets;
  Iterable<LoggedSet> get done =>
      skipped ? const [] : sets.where((s) => s.completed);
  int get repCount => done.fold(0, (total, s) => total + (s.reps ?? 0));
  double get volume => done.fold(0, (total, s) => total + s.volume);
  double get heaviest =>
      done.fold(0, (best, s) => (s.weight ?? 0) > best ? s.weight! : best);
}

class WorkoutSession {
  const WorkoutSession(
    this.id,
    this.name,
    this.date,
    this.completed,
    this.exercises,
  );
  final int id;
  final String name;
  final DateTime date;
  final bool completed;
  final List<SessionExercise> exercises;
  int get setCount => exercises.fold(0, (total, e) => total + e.done.length);
  int get repCount => exercises.fold(0, (total, e) => total + e.repCount);
  double get volume => exercises.fold(0, (total, e) => total + e.volume);
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String number(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

class ProgressPoint {
  const ProgressPoint(this.session, this.exercise);
  final WorkoutSession session;
  final SessionExercise exercise;
}

List<ProgressPoint> exerciseProgress(
  List<WorkoutSession> sessions,
  int exerciseId,
) {
  final points = <ProgressPoint>[];
  for (final session in sessions.where((s) => s.completed)) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseId == exerciseId && exercise.done.isNotEmpty) {
        points.add(ProgressPoint(session, exercise));
      }
    }
  }
  points.sort((a, b) {
    final date = a.session.date.compareTo(b.session.date);
    return date != 0 ? date : a.session.id.compareTo(b.session.id);
  });
  return points;
}
