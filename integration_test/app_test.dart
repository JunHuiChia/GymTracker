import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/workout_store.dart';
import 'package:gym_tracker/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const variant = String.fromEnvironment(
    'REVIEW_VARIANT',
    defaultValue: 'light',
  );
  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  Finder formField(String label) => field(label);

  testWidgets(
    'create a plan, log variable sets, resume, finish and review stats',
    (tester) async {
      final location = path.join(
        await getDatabasesPath(),
        'gym_tracker_integration.db',
      );
      await deleteDatabase(location);
      var store = await WorkoutStore.open(databasePath: location);
      debugPrint('Integration: database opened');
      await tester.pumpWidget(GymTrackerApp(store: store));
      await tester.pumpAndSettle();
      debugPrint('Integration: first screen settled');
      await binding.convertFlutterSurfaceToImage();
      debugPrint('Integration: screenshot surface ready');
      Future<void> capture(String name) async {
        debugPrint('Integration: capturing $name');
        FocusManager.instance.primaryFocus?.unfocus();
        // Android's IME animation finishes outside Flutter's frame scheduler.
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$variant-phone-$name');
      }

      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(finder, findsWidgets);
        await tester.pumpAndSettle();
      }

      await capture('empty');
      await tester.tap(find.text('Create plan'));
      await tester.pumpAndSettle();
      await tester.enterText(formField('Plan name'), 'Sample upper body');
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(formField('Exercise name'), 'Sample cable row');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save exercise'));
      await tester.tap(find.text('Save exercise'));
      await tester.pumpAndSettle();
      expect(
        (await store.exercises()).where((e) => e.name == 'Sample cable row'),
        hasLength(1),
      );
      await tester.enterText(field('Search exercises'), 'bench');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('catalogue');
      await tester.tap(find.text('Barbell bench press'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Search exercises'), 'Sample cable row');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Sample cable row'));
      await tester.pumpAndSettle();
      await capture('plan');
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();
      expect(find.text('Sample upper body'), findsOneWidget);
      // Recorded sample history gives the redesign real prior-set evidence and a trend.
      final plan = (await store.plans()).single;
      for (final sample in [(21, 45.0), (7, 47.5)]) {
        final prior = await store.startSession(
          plan,
          DateTime.now().subtract(Duration(days: sample.$1)),
        );
        final priorSet = (await store.session(prior))
            .exercises
            .first
            .sets
            .first;
        await store.saveSet(priorSet.id, sample.$2, 10, true);
        await store.finishSession(prior);
      }
      await capture('workouts');
      await tester.tap(find.text('Start workout'));
      await waitFor(find.text('Choose any exercise'));
      await capture('checklist');
      // Start with the second-listed exercise: equipment availability determines order.
      await tester.tap(find.text('Sample cable row'));
      await waitFor(field('Weight'));
      await tester.ensureVisible(find.text('Skip exercise'));
      await tester.tap(find.text('Skip exercise'));
      await tester.pumpAndSettle();
      final back = find.widgetWithText(FilledButton, 'Back to workout');
      await Scrollable.ensureVisible(tester.element(back), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await waitFor(find.text('Choose any exercise'));
      await tester.tap(find.text('Barbell bench press'));
      await waitFor(field('Weight'));
      for (var i = 0; i < 3; i++) {
        final kg = formField('Weight').at(i);
        await tester.ensureVisible(kg);
        await tester.enterText(kg, ['50', '50', '45'][i]);
        await tester.pumpAndSettle();
        final reps = formField('Reps').at(i);
        await tester.ensureVisible(reps);
        await tester.enterText(reps, ['10', '8', '12'][i]);
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(Checkbox).at(i));
        await tester.tap(find.byType(Checkbox).at(i));
        await tester.pumpAndSettle();
        if (i == 1) {
          final partialBack = find.widgetWithText(
            FilledButton,
            'Back to workout',
          );
          await Scrollable.ensureVisible(
            tester.element(partialBack),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(partialBack);
          await waitFor(find.text('Choose any exercise'));
          expect(find.text('2 of 3 sets complete'), findsOneWidget);
          await capture('checklist');
          await tester.tap(find.text('Barbell bench press'));
          await waitFor(field('Weight'));
        }
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, 800));
      await tester.pumpAndSettle();
      await capture('logger');
      final returnToWorkout = find.widgetWithText(
        FilledButton,
        'Back to workout',
      );
      await Scrollable.ensureVisible(
        tester.element(returnToWorkout),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(returnToWorkout);
      await waitFor(find.text('Choose any exercise'));
      expect(find.text('Next exercise'), findsNothing);
      final active = (await store.activeId())!;
      expect((await store.session(active)).volume, 1440);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await store.database.close();
      store = await WorkoutStore.open(databasePath: location);
      await tester.pumpWidget(GymTrackerApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Resume Sample upper body'), findsOneWidget);
      await tester.tap(find.text('Resume Sample upper body'));
      await waitFor(find.text('Choose any exercise'));
      final review = find.widgetWithText(FilledButton, 'Review workout');
      await Scrollable.ensureVisible(tester.element(review), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(review);
      await waitFor(find.text('3 completed sets · 30 reps'));
      expect(find.text('3 completed sets · 30 reps'), findsOneWidget);
      await capture('summary');
      final finish = find.widgetWithText(FilledButton, 'Finish workout');
      await Scrollable.ensureVisible(tester.element(finish), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(finish);
      await waitFor(find.text('History'));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await capture('history');
      await tester.tap(find.text('Stats'));
      await waitFor(find.text('50 kg'));
      await capture('stats');
      await tester.tap(find.text('Volume'));
      await waitFor(find.text('1440 kg·reps'));
      expect(find.text('1440 kg·reps'), findsWidgets);
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      await capture('chart');
      expect(tester.takeException(), isNull);
      expect((await store.history()).first.volume, 1440);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await store.database.close();
      await deleteDatabase(location);
    },
  );
}
