import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/workout_store.dart';
import 'package:gym_tracker/main.dart';
import 'package:gym_tracker/models.dart';
import 'package:gym_tracker/screens/exercise_picker.dart';
import 'package:gym_tracker/screens/plan_editor.dart';
import 'package:gym_tracker/screens/stats_screen.dart';
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

  for (final brightness in Brightness.values) {
    test(
      'theme text and interactive surfaces have sufficient contrast in $brightness',
      () {
        final c = appTheme(brightness).colorScheme;
        double contrast(Color a, Color b) {
          final x = a.computeLuminance(), y = b.computeLuminance();
          return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
        }

        for (final pair in [
          (c.onSurface, c.surface),
          (c.onSurfaceVariant, c.surface),
          (c.onPrimary, c.primary),
          (c.onPrimaryContainer, c.primaryContainer),
        ]) {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.secondary, c.surface), greaterThanOrEqualTo(3));
        expect(
          contrast(c.outline, c.surfaceContainerLowest),
          greaterThanOrEqualTo(3),
        );
      },
    );
  }

  testWidgets(
    'exercises can be opened out of order and saved sets stay attached to the chosen exercise',
    (tester) async {
      final exercises = (await tester.runAsync(() => store.exercises()))!;
      final id = (await tester.runAsync(() async {
        await store.savePlan(
          'Flexible workout',
          exercises.take(3).map((e) => PlanEntry(e, sets: 1)).toList(),
        );
        return store.startSession((await store.plans()).single, DateTime.now());
      }))!;
      Future<void> settle([Future<void> Function()? action]) async {
        await tester.runAsync(() async {
          if (action != null) await action();
          for (var i = 0; i < 4; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 100));
          }
        });
        await tester.pumpAndSettle();
      }

      await settle(() => tester.pumpWidget(GymTrackerApp(store: store)));
      await settle(() => tester.tap(find.text('Resume Flexible workout')));
      expect(find.text('Choose any exercise'), findsOneWidget);
      await settle(() => tester.tap(find.text(exercises[2].name)));
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await settle(() async {
        await tester.enterText(field('Weight'), '50');
        await tester.enterText(field('Reps'), '10');
      });
      await settle(() => tester.tap(find.byType(Checkbox)));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(find.text('Back to workout'));
      await settle(() => tester.tap(find.text('Back to workout')));
      expect(find.text('Choose any exercise'), findsOneWidget);
      expect(find.text('Next exercise'), findsNothing);
      final session = await tester.runAsync(() => store.session(id));
      expect(session!.exercises[2].volume, 500);
      expect(session.exercises.first.done, isEmpty);
      await settle(() => tester.tap(find.text(exercises.first.name)));
      expect(
        tester.widget<TextField>(field('Weight')).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty app has usable navigation and create-plan entry', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(GymTrackerApp(store: store));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pumpAndSettle();
    expect(find.text('Create plan'), findsOneWidget);
    expect(find.text('A routine you can return to'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Your training history starts here'), findsOneWidget);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('See your progress take shape'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan and custom exercise forms reject empty names', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: PlanEditor(store: store)));
    await tester.tap(find.text('Save plan'));
    await tester.pump();
    expect(find.text('Enter a plan name'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: ExerciseEditor(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    expect(find.text('Enter an exercise name'), findsOneWidget);
  });

  testWidgets('long plans keep targets and save accessible on compact phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final plan = WorkoutPlan(
      1,
      'A longer upper body routine',
      List.generate(
        20,
        (index) => PlanEntry(
          Exercise(
            id: index + 1,
            name: 'A long exercise name for machine variation ${index + 1}',
            muscle: 'Back',
            equipment: 'Machine',
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: PlanEditor(store: store, plan: plan),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save plan'), findsOneWidget);
    await tester.drag(find.byType(ReorderableListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('compact stats layout handles large text in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = WorkoutSession(1, 'Upper body', DateTime.now(), true, [
        const SessionExercise(1, 1, 'Barbell bench press', false, false, [
          LoggedSet(1, 0, 50, 10, true),
          LoggedSet(2, 1, 50, 8, true),
          LoggedSet(3, 2, 45, 12, true),
        ]),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(brightness),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(body: StatsScreen(sessions: [session])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1440 kg·reps'), findsOneWidget);
      final colors = appTheme(brightness).colorScheme;
      for (final chip in tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      )) {
        final ink = chip.labelStyle!.color!.computeLuminance();
        final ground = (chip.selected ? colors.primary : colors.surface)
            .computeLuminance();
        final ratio =
            ((ink > ground ? ink : ground) + 0.05) /
            ((ink > ground ? ground : ink) + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
