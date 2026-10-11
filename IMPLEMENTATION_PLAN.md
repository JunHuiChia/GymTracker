# GymTracker MVP implementation plan

Build a Flutter Android app for personal use, installed from a signed APK. All exercises, plans, workout logs and statistics live on the device and work without internet access. The project folder is currently empty; this plan assumes a new Flutter project.

## 1. MVP scope and working assumptions

- Create, rename, edit and archive multiple workout plans.
- Each plan contains exercises with an optional target set count and rep count. A stable display order is organisational only; workouts never require exercises to be performed in that order.
- Choose from a bundled exercise catalogue or create a custom exercise.
- Start a workout from a plan, choose its performed date (today by default), and log each set's weight in kg and repetitions.
- Save progress throughout the workout, resume after closing the app, and finish with a summary of completed and skipped exercises.
- Browse and correct past workouts, with exercise progress and overall workout statistics.

**Weight convention:** record total external load. Barbell weight includes the bar; two 10 kg dumbbells are recorded as 20 kg. Show this guidance in the logger. For machines, record the displayed load and compare the same exercise/equipment consistently. Bodyweight exercises accept 0 kg and still track reps and sets; their bodyweight load is not estimated.

**Effective weight assumption:** use the clearer label **training volume**, calculated as the sum of `weight_kg × reps` for completed sets. Three sets of 10 reps at 50 kg produce 1,500 kg·reps. This measures logged external load, not physiological effectiveness or strength by itself. If “effective weight” means something else, settle that definition before implementing statistics.

## 2. Screens and gym workflow

Use three main tabs: **Workouts**, **History**, and **Stats**. Open the exercise catalogue from the workout plan editor; it does not need its own main tab.

| Screen | Behaviour |
|---|---|
| Workouts | List plans, create/edit a plan, start a workout, and prominently resume an unfinished workout. |
| Plan editor | Name the plan; search/select exercises; add custom exercises; reorder/remove exercises; set optional targets. |
| Exercise catalogue | Search by name, filter by muscle group/equipment, add/edit/archive custom exercises. |
| Workout logger | Select date; see exercise progress; open or revisit any exercise; enter kg/reps per set; mark a set complete; add/remove sets; skip an exercise; return to the workout and choose any exercise next. |
| Workout summary | Show every exercise, recorded sets, totals and skipped items; finish or return to logging. |
| History | List dated workouts; open details; correct date or set entries; delete a workout after confirmation. |
| Stats | Workout frequency and exercise-specific charts, totals and records. |

Typical flow: **choose plan → start today's workout → log sets for each exercise → review → finish**.

- Show the previous completed workout's results for that exercise beside the inputs. A “copy previous sets” action may populate inputs, but never mark copied sets complete.
- Use large touch targets, persistent labels, readable contrast, a decimal keyboard for kg and an integer keyboard for reps. Keep the active input visible above the keyboard.
- Autosave valid changes locally, serialize writes, flush pending changes before navigating or finishing, and visibly report save failures. Do not show a set as saved when a write failed.
- Allow one active workout for the MVP. Starting another offers resume or explicit discard; never silently overwrite it.
- Permit a finished workout with skipped exercises, but require at least one completed set. Drafts and unchecked sets do not affect statistics.

## 3. Local data model

Use SQLite with foreign keys, transactions and numbered schema migrations. Flutter's [SQLite guide](https://docs.flutter.dev/cookbook/persistence/sqlite) documents `sqflite` for local database access.

| Entity | Main fields |
|---|---|
| Exercise | ID, name, muscle group, equipment, bodyweight/load tracking type, built-in/custom flag, archived flag. |
| WorkoutPlan | ID, name, archived flag. |
| PlanExercise | ID, plan ID, exercise ID, position, optional target sets/reps. |
| WorkoutSession | ID, optional source plan ID, plan name snapshot, performed date, draft/completed status, created/completed timestamps. |
| SessionExercise | ID, session ID, exercise ID, name and tracking-type snapshots, position, skipped flag. |
| LoggedSet | ID, session-exercise ID, position, weight in kg, reps, completed flag. |

Store performed dates as local calendar dates (`YYYY-MM-DD`), independently of technical timestamps. Store weight as a finite, nonnegative decimal value and reps as positive integers for completed sets; unfinished inputs can remain empty. Zero kg is valid for bodyweight movements.

Important rules:

- Starting a workout copies the plan's name, exercises, order and targets into session records in one transaction. Later plan changes cannot rewrite history or an active session.
- Keep stable exercise IDs so the same exercise can be tracked across several plans. A materially different movement is a new exercise; editing a name preserves identity.
- Archive referenced exercises/plans instead of deleting them. Existing plans and sessions retain their references; archived exercises are hidden from new selections.
- Deleting a workout removes its exercises and sets transactionally after confirmation.
- Seed built-in exercises once using stable IDs; restarting/upgrading must not duplicate them or overwrite custom entries.
- Never rebuild or clear the database to handle an upgrade or failed migration. Report failure and preserve the existing data.
- Derive statistics from stored logs; do not maintain a separate statistics table that can become stale after corrections.

## 4. Initial exercise catalogue

Bundle a small curated catalogue as Dart data, with names, muscle groups, equipment and tracking type. No remote exercise API or images are needed.

| Group | Initial exercises |
|---|---|
| Chest | Barbell bench press, incline barbell bench press, dumbbell bench press, incline dumbbell bench press, cable fly, chest press machine. |
| Back | Deadlift, barbell row, dumbbell row, seated cable row, lat pulldown, pull-up. |
| Legs/glutes | Back squat, front squat, leg press, Romanian deadlift, leg extension, leg curl, hip thrust, dumbbell lunge. |
| Shoulders | Barbell overhead press, dumbbell shoulder press, lateral raise, reverse fly, face pull. |
| Arms | Barbell curl, dumbbell curl, hammer curl, triceps pushdown, overhead triceps extension, dip. |
| Calves/core | Standing calf raise, seated calf raise, cable crunch, hanging knee raise. |

Keep machine, barbell and dumbbell variants separate. Time-based exercises such as planks are outside the initial reps-based model.

## 5. Statistics and progress

Only completed sets in completed sessions count. Edits/deletions refresh the results immediately. Order results by performed date and use separate entries when there are multiple sessions on one date.

**Overall:** completed workouts in a selected date range, workouts per week, total completed sets and total logged training volume.

**For a selected exercise:** a session history table and a selectable chart for heaviest completed load, total reps, completed sets or training volume. Default the range to the last three months and provide an all-time option.

- Heaviest load: maximum completed-set kg for the exercise in that session, with the corresponding reps visible.
- Reps and sets: sum reps and count completed sets for that exercise in the session.
- Volume: sum `kg × reps`; varying weights/reps are calculated per set rather than multiplying a single summary value.
- Personal records: highest logged load with its reps, most reps at a selected load, and highest session volume.
- Show changes against the previous completed session, retaining the underlying set details so a heavier low-rep set is not presented as a directly equivalent performance.
- For bodyweight exercises, emphasize reps/sets; suppress a misleading zero-load volume chart. Added external load, when recorded, is labelled as external load only.
- Empty history shows guidance; a single session shows one data point without an improvement percentage. Never divide by a zero previous value.

Avoid estimated one-rep max and a single “strength score” in the MVP: the requested raw metrics are sufficient and easier to interpret.

## 6. Flutter implementation approach

- Flutter/Dart with Material widgets, Android as the only configured delivery platform.
- `sqflite` plus `path` for storage; keep SQL and database operations in one concrete database/store class.
- Screen-local state for forms and a small Flutter `ChangeNotifier` controller for the active workout. Flutter documents this primitive in its [state-management guide](https://docs.flutter.dev/data-and-backend/state-mgmt/simple); a separate state framework is unnecessary for this scope.
- Standard Flutter navigation for the small screen set.
- Add [fl_chart](https://pub.dev/packages/fl_chart) when implementing progress charts; it already provides line/bar charts and avoids writing chart rendering and interaction from scratch.
- Keep domain models, database/catalogue code, screens and the active-workout controller separate. Add files as each feature needs them, without generic repository interfaces, dependency injection frameworks or generated layers.

Implementation reaches `pubspec.yaml`, Flutter source, bundled catalogue data, database migrations, tests and Android manifest/build/signing configuration. Configure Android backup rules to prevent cloud backup of the workout database, consistent with device-only storage; verify the applicable Android behaviour during release preparation.

## 7. Implementation stages and acceptance checks

Complete these in order. Each stage should leave a working app that can be demonstrated on Android.

1. **Foundation and persistence**
   - Create the Flutter Android project, confirm the development toolchain, establish application ID/theme/navigation, create the database and seed exercises.
   - Check: catalogue appears offline, survives restart, and repeated startup does not duplicate exercises. Test creation, constraints and seed behaviour.

2. **Exercises and workout plans**
   - Implement catalogue search/custom exercises and plan creation/editing/reordering/archiving.
   - Check: create two different plans, add a custom exercise, reopen the app and recover their saved contents/order. Test referenced-item archival and invalid inputs.

3. **Workout logging**
   - Implement session snapshots, date selection, per-set inputs, completion/skipping, autosave/resume and summary/finish.
   - Check: log sets with different loads/reps, interrupt and reopen the app, then finish with correct saved values. Test snapshot isolation, drafts excluded from totals, write ordering and save-failure handling.

4. **History and corrections**
   - Implement workout list/detail, date/set corrections and confirmed deletion.
   - Check: backdated workouts appear in the correct order; correcting a log preserves unrelated workouts. Test transactional deletion and history retained after plan edits.

5. **Statistics**
   - Implement queries/calculations, exercise selector, date ranges, records and charts.
   - Check: a known fixture of 50 kg × 10, 50 kg × 8 and 45 kg × 12 yields 3 sets, 30 reps and 1,440 kg·reps. Test varying sets, skipped/draft entries, bodyweight, zero baselines, multiple sessions on one date and updates after corrections.

6. **Android release and personal gym trial**
   - Run formatting/static analysis and focused unit/widget tests; run an Android integration flow from custom exercise and plan creation through logging, restart, history and statistics.
   - Check a real phone for keyboard behaviour, accessibility, background/resume and offline use. Exercise migration from an earlier database version and upgrade an installed APK with existing logs.
   - Configure release signing, keep the private keystore outside version control, and retain the same key/application ID for future updates. Build one signed universal APK initially, following Flutter's [Android release guide](https://docs.flutter.dev/deployment/android).
   - Deliver the APK, source and brief install/update instructions. Verify installation and an update preserving existing data on the personal device before calling the MVP complete.

## 8. Scope boundaries and risks

Defer accounts, cloud sync, iOS/web, Play Store publishing, social features, exercise media, coaching, timers, supersets, wearable integrations and automatic progression. Manual export/restore can follow the MVP; it is not required for the logging workflow.

Device-only storage means uninstalling, clearing app data or losing the phone can lose workout history. The first release has no recovery facility; the user accepted this risk on 11 October 2026. Keep the release signing key securely backed up so updates remain installable. Machine loads and bodyweight movements have comparison limits; describe those next to the affected metrics instead of claiming a universal measure of strength.

Implementation status (11 October 2026): stages 1–5 are implemented. SQLite stores the catalogue, plans, snapshots and variable set logs. Android integration has exercised custom exercise creation, plan creation, completed/skipped sets, database reopening/resume, history and the 1,440 kg·reps statistics fixture. Fifteen database/interface tests and static analysis pass. Version 0.2.0 rebuilds UI components around the approved Field Notes/terracotta mockup and keeps exercise choice independent of display order. Twenty native light/dark/enlarged-text captures passed independent fidelity review. The signed release update from 0.1.0 to 0.2.0 preserved a synthetic plan and completed workout on the emulator. Physical-phone gym trial, installed update with personal records, migration from a different released schema and hardware accessibility checks remain outstanding. See README.md for installation and key backup instructions.
