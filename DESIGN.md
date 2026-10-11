---
name: GymTracker
description: A restrained native Android workout log with clear set-by-set progress.
colors:
  primary-seed: "#174EA6"
typography:
  headline-small:
    fontFamily: Roboto
    fontSize: "24sp"
    fontWeight: 400
    lineHeight: 1.33
    letterSpacing: "0sp"
  title-large:
    fontFamily: Roboto
    fontSize: "22sp"
    fontWeight: 400
    lineHeight: 1.27
    letterSpacing: "0sp"
  title-medium:
    fontFamily: Roboto
    fontSize: "16sp"
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: "0.15sp"
  title-small:
    fontFamily: Roboto
    fontSize: "14sp"
    fontWeight: 500
    lineHeight: 1.43
    letterSpacing: "0.1sp"
  body-large:
    fontFamily: Roboto
    fontSize: "16sp"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.5sp"
  body-medium:
    fontFamily: Roboto
    fontSize: "14sp"
    fontWeight: 400
    lineHeight: 1.43
    letterSpacing: "0.25sp"
  body-small:
    fontFamily: Roboto
    fontSize: "12sp"
    fontWeight: 400
    lineHeight: 1.33
    letterSpacing: "0.4sp"
  label-large:
    fontFamily: Roboto
    fontSize: "14sp"
    fontWeight: 500
    lineHeight: 1.43
    letterSpacing: "0.1sp"
rounded:
  field: "4dp"
  resume: "16dp"
spacing:
  micro: "4dp"
  compact: "8dp"
  paired: "12dp"
  group: "16dp"
  page: "20dp"
  section: "24dp"
  empty: "32dp"
components:
  button-filled:
    typography: "{typography.label-large}"
    height: "48dp minimum"
    width: "48dp minimum"
  button-outlined:
    typography: "{typography.label-large}"
    height: "48dp minimum"
    width: "48dp minimum"
  input-outlined:
    rounded: "{rounded.field}"
  resume-strip:
    rounded: "{rounded.resume}"
    padding: "{spacing.group}"
  set-completion:
    width: "48dp"
    height: "56dp"
---

# Design System: GymTracker

## Overview

**Creative North Star: "Circuit station board"**

The user-selected exercise checklist and focused set logger give the interface its character: orderly, practical and calm between sets. An ordered exercise roster, visible completion icons and legible numbers carry the experience. Familiar Android controls make the next action apparent.

Cool-neutral Material surfaces and restrained blue emphasis support the personal workout log. Logging takes precedence over decoration. The chosen workflow avoids a motivational dashboard; the declined exploration motifs are not additional design rules.

**Key Characteristics:**
- Native Material 3 controls with system light and dark themes.
- Divided rows, readable quantities and visible completion states.
- Phone-first spacing with scrolling, wrapping and font scaling.
- Sparse emphasis reserved for actions, resuming and recorded progress.

This is a scan of the implemented Flutter system, not a new visual identity. Frontmatter sizes use Android design units: dp for geometry, sp for base typography before system scaling. Flutter expresses both as logical values; physical screenshot pixels vary with device density. The sidecar's browser snippets are explicitly nonshipping illustrations, not authored application CSS.

Evidence: `lib/main.dart` owns the theme; `lib/screens/common.dart` owns shared layout, empty states and dates; `home_screen.dart`, `plan_editor.dart`, `exercise_picker.dart`, `session_screen.dart` and `stats_screen.dart` own the patterns below. Typography and widget defaults were checked against the installed Flutter 3.47.7 SDK (`packages/flutter/lib/src/material/typography.dart`, `filled_button.dart`, `input_border.dart`). `.impeccable/review/` holds light-phone and dark-large-phone rendered evidence; final recapture and finish verdict are separate review outputs.

## Colors

The palette is a deep blue seed transformed into brightness-aware Material roles over cool-neutral surfaces.

### Primary
- **Deep blue seed** (`colors.primary-seed`): input to `ColorScheme.fromSeed`, not the exact rendered primary color. Filled actions, completed exercise icons, empty-state icons and chart lines use the generated `primary` role. Their foregrounds follow Material role pairings.
- The resume strip uses generated `primaryContainer`. The default navigation, chips and FAB use their Material 3 generated roles; there are no independently authored secondary or tertiary brand colors.

### Neutral
- The scaffold uses generated `surface`. Default text, dividers and outlined fields use Material foreground and outline roles. Light/dark variants are generated at runtime and are intentionally not replaced with guessed hex tokens.
- Form validation and logger errors use generated `error` and the native error treatment.

**The Semantic Pairing Rule.** Resolve colors from the active `ColorScheme` and preserve its foreground/background pairings; the seed is not a substitute for `primary`.

## Typography

**Display Font:** no separate display face is used.
**Body Font:** Android's default Roboto through Flutter Material typography; no bundled custom font.
**Character:** familiar, quiet sans-serif roles establish hierarchy through size and weight, with sentence-case labels and explicit units.

### Hierarchy
- **Headline small:** exercise logger heading and empty-state title.
- **Title large:** plan names, section headings and overview quantities.
- **Title medium:** exercise names, recorded-session headings and best-in-range values.
- **Title small:** numbered set labels.
- **Body large:** prominent instructions and session summaries.
- **Body medium:** supporting exercise details and totals labels.
- **Body small:** saving guidance, supporting status and chart axis labels.
- **Label large:** native action labels. Navigation and chips retain their own Material role defaults.

Exact base metrics are in frontmatter. These are the installed Material 2021 English-like defaults, not a custom modular scale. App bars inherit native title typography. System text scaling remains enabled.

**The Scaling Rule.** Let text grow and layouts reflow; do not reduce type to keep a narrow row fixed.

## Layout

Shared `PageBody` aligns content at the top and caps its width at 840 dp. Primary pages use 20 dp horizontal gutters; the shared empty state uses 32 dp padding. Small gaps group related controls, while 20–24 dp gaps separate sections. Lists scroll rather than forcing every item into the first viewport.

Home navigation becomes a labelled rail at 700 dp viewport width; below it, the three destinations use a bottom navigation bar. This is adaptive layout support, not a separate tablet product. App bars align their titles to the start. `SafeArea` protects body content.

Catalogue search and filters share one workflow above the exercise list. The two filters have a 12 dp gap at ordinary scale and stack at full width when the scaled 14 sp text exceeds 16 logical pixels. Totals and metric chips wrap; logger secondary actions wrap as space demands. Set inputs remain paired with a 12 dp gap and a separate completion control.

Reserve bottom scroll padding where the FAB could cover rows (112 dp on Workouts; 100 dp on the catalogue). Keep the plan save action in its existing bottom area with 20 dp padding. Preserve visible labels, accessible move-up/down alternatives to dragging, and descriptive icon tooltips.

Dates from the current year use the locale's medium-date format; dates in other years use the short-date format including the year. Date selectors use the native Material picker.

## Elevation & Depth

The app uses a hybrid of tonal grouping and native Material elevation. Lists and logger content are flat with dividers; the resume strip is a tonal surface with no authored shadow. FABs, menus and dialogs retain Flutter Material defaults. Filled buttons rest at zero elevation and inherit a 1 dp hover elevation in the installed SDK. No custom shadow or motion vocabulary is authored; do not invent web box-shadow values for the native app. Native state layers, ripple feedback, focus and route transitions remain framework controlled.

## Shapes

The resume strip uses gently rounded corners (`rounded.resume`), outlined inputs use the framework's small corner radius (`rounded.field`), and filled/outlined buttons inherit `StadiumBorder`. Chips, navigation indicators, dialogs and the extended FAB retain Material 3 shapes. Dividers organize flat content; repeated exercise rows are not wrapped in decorative cards.

## Components

### Buttons

Clear, familiar actions. Filled buttons own primary actions such as saving or advancing; outlined buttons support retry and adding a set; text buttons support contextual secondary actions. Filled and outlined buttons have the theme's minimum 48-by-48 dp size. Their padding adapts with text scaling through Flutter defaults. Disabled, pressed, hover and keyboard-focus states remain native; the installed filled-button state layers use 8% on-primary for hover and 10% for pressed/focused.

### Chips

Compact metric choices, not tags. Stats uses wrapped `ChoiceChip` controls for Weight, Reps, Sets and Volume, with the native visible selected state. Bodyweight exercises expose Reps and Sets. Spacing and run spacing are 8 dp.

### Cards / Containers

The active-workout resume strip is the distinctive container: generated `primaryContainer`, 16 dp internal padding and the documented resume radius. Its row has a play icon, title, saved-set summary and chevron. Ordinary plans, exercise lists and history use content rows and dividers.

### Inputs / Fields

Outlined, persistently labelled native fields. Numeric inputs state Weight with kg suffix or Reps; target sets/reps use the same outline vocabulary. Native focus, validation error and disabled treatments remain intact. Search includes a search icon; selection fields use native dropdowns. Never replace field labels with placeholders alone.

### Navigation

Workouts, History and Stats use native bottom destinations on phones and a labelled rail on wide layouts. Each destination has an outlined default icon and filled selected icon. Detail pages use back navigation and a named app bar; destructive commands belong to their established menu or confirmation flow.

### Exercise checklist and focused set logger

Exercise rows show their name, completed/target set count, status icon and chevron. The logger repeats numbered sets with two expanded numeric inputs and a checkbox in a 48-by-56 dp box, separated by 8 dp from the inputs. Completion has a semantic label and validates the entries. Set removal is a labelled icon action above the fields. Saved-on-device status and progression actions sit below the repeated set rows.

### Recorded progress

Stats presents range, overview totals, exercise selection and wrapped metric choices in one scroll flow. A 220 dp chart uses a 3 dp primary line, straight segments and visible points. It has a semantic description and exact session values below it; the chart is not the sole representation of data.

## Do's and Don'ts

### Do:
- **Do** use the active Material theme and semantic color roles.
- **Do** preserve 20 dp page gutters, minimum 48 dp filled/outlined controls and the shared width cap.
- **Do** keep related controls in their existing workflow and allow wrapping, scrolling and font scaling.
- **Do** show completion with icons and text, and quantities with kg, reps, sets or kg·reps.
- **Do** check compact and wide layouts, light/dark themes, keyboard access and crowded data before completion.

### Don't:
- **Don't** use the seed as a guessed rendered role color or hard-code a light palette into dark mode.
- **Don't** add decorative cards around every row or foreign motifs from declined concepts.
- **Don't** replace native state feedback or labelled controls with decorative custom widgets.
- **Don't** present sample review records as real user history.
