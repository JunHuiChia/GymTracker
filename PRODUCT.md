# GymTracker

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter and Dart, SQLite through sqflite, local storage only. Personal Android APK distribution.

## Users

The owner uses a phone during gym sessions to select a plan, record sets as exercises are performed, and review progress later.

## Product Purpose

Replace a paper workout log with reusable plans and reliable dated set records. Success means completing a gym session without losing entries and seeing weight, reps, sets and training volume over time.

## Operating Context

Use between sets in a gym. Metric kg only. Workouts default to today but can be backdated. Internet access is unnecessary. Closing the app must preserve saved workout progress.

## Capabilities and Constraints

Multiple workout plans; built-in lifting exercises and custom additions; individual set loads/reps; workout history and exercise statistics. Exercises can be performed in any order based on gym equipment availability. Display order is only for organisation, never a required sequence; every exercise is directly accessible and can be revisited. Past sessions stay independent of plan edits. No accounts, cloud sync, timers or coaching. The user explicitly accepts that device loss/uninstall can lose history. Training volume means the sum of completed-set kg multiplied by reps.

## Product Principles

- Logging takes precedence over decoration.
- Support flexible exercise choice throughout a workout; completion counts describe progress without imposing a sequence.
- Saved records stay intact through plan edits and restarts.
- Use familiar Android controls and make each action clear.
- Statistics show recorded evidence rather than invented strength scores.

## Accessibility & Inclusion

Honor Android font scaling, system theme, keyboard access, adequate contrast and touch targets. Check crowded lists and compact phone layouts. Android phones are the initial delivery target; tablets are not a separate delivery target yet.

## Evidence on Hand

IMPLEMENTATION_PLAN.md contains the agreed functional plan. The user approved Field Notes with terracotta on 11 October 2026, using output/design-mockups/04-field-notes-terracotta.png as the visual reference. Its component composition must carry through to the working screens, not just its colours. Sample test records must not appear as personal history.
