---
name: GymTracker
description: A warm native training logbook with focused set entry and recorded progress.
colors:
  olive: "#606c38"
  forest: "#283618"
  cream: "#fefae0"
  terracotta: "#bc6c25"
  tan: "#dda15e"
  light-primary-container: "#eeead2"
  light-secondary-container: "#f6e3c5"
  light-on-secondary-container: "#653814"
  light-on-surface-variant: "#515d3c"
  light-surface-container-lowest: "#fffdf0"
  light-surface-container-low: "#fcf8df"
  light-surface-container: "#f4efd7"
  light-surface-container-high: "#eee8cc"
  light-surface-container-highest: "#e9e3c5"
  light-outline: "#7b855e"
  light-outline-variant: "#d7d7b9"
  light-error: "#a13024"
  dark-primary: "#bacb8d"
  dark-primary-container: "#3f4b29"
  dark-secondary: "#efb27e"
  dark-secondary-container: "#58361c"
  dark-on-surface-variant: "#d4d8bd"
  dark-surface-container-lowest: "#202b13"
  dark-surface-container-low: "#303e20"
  dark-surface-container: "#354324"
  dark-surface-container-high: "#3d4b2c"
  dark-surface-container-highest: "#465433"
  dark-outline: "#9ba77e"
  dark-outline-variant: "#586544"
  dark-error: "#ffb4a5"
typography:
  headline-large:
    fontFamily: Lora
    fontSize: "32sp"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.5sp"
  headline-medium:
    fontFamily: Lora
    fontSize: "28sp"
    fontWeight: 600
    lineHeight: 1.29
    letterSpacing: "-0.5sp"
  headline-small:
    fontFamily: Lora
    fontSize: "28sp"
    fontWeight: 600
    lineHeight: 1.33
    letterSpacing: "-0.5sp"
  title-large:
    fontFamily: Lora
    fontSize: "22sp"
    fontWeight: 700
    lineHeight: 1.27
    letterSpacing: "-0.5sp"
  title-medium:
    fontFamily: Roboto
    fontSize: "16sp"
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: "0.15sp"
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
  segment: "8dp"
  field: "10dp"
  container: "12dp"
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
    height: "52dp minimum"
    width: "48dp minimum"
    rounded: "{rounded.container}"
  button-outlined:
    typography: "{typography.label-large}"
    height: "48dp minimum"
    width: "48dp minimum"
    rounded: "{rounded.container}"
  input-outlined:
    rounded: "{rounded.field}"
    padding: "16dp 16dp"
  resume-strip:
    rounded: "{rounded.resume}"
    padding: "{spacing.group}"
  plan-container:
    rounded: "{rounded.container}"
    padding: "{spacing.group}"
  metric-segments:
    rounded: "{rounded.segment}"
    height: "48dp minimum"
    padding: "8dp 8dp"
  set-completion:
    width: "48dp"
    height: "56dp"
---

# Design System: GymTracker

## Overview

**Creative North Star: "Field Notes with terracotta"**

A warm training logbook pairs cream paper, forest ink and olive controls with restrained terracotta headings and progress accents. Lora serif headings give the log its character; native sans-serif controls keep set entry clear between exercises.

The approved reference is `output/design-mockups/04-field-notes-terracotta.png`. The working Flutter screens carry its outlined containers, compact set table and chart-led statistics hierarchy. Light and dark themes preserve the same identity. Exercise numbers never impose a training sequence; numbers identify sets only.

**Key Characteristics:**
- Warm paper and ink roles, olive actions and copper progress accents.
- Bundled Lora headings with native Android sans-serif controls.
- Compact aligned numeric entry and clear completion states.
- Familiar Material 3 interaction, font scaling and phone-first scrolling.

This is a scan of the approved native implementation. `lib/theme.dart` owns theme roles; `lib/screens/common.dart` owns shared layout; the screen files own composition. Geometry uses dp-equivalent Flutter logical pixels; typography uses sp-equivalent base values before system scaling. Browser previews in the sidecar are explicitly illustrative and do not ship in the APK.

## Colors

The palette feels like a working notebook: warm paper, botanical ink and restrained copper marks.

### Primary
- **Olive** (`colors.olive`): light primary actions, resume strip, selected metric segment and completion feedback. Pair with cream foreground.
- **Light olive** (`colors.dark-primary`): dark primary actions; pair with forest foreground.
- **Primary containers:** pale paper-olive in light mode and shaded olive in dark mode group totals, previous-workout information and Add set. Their foregrounds are forest and cream respectively.

### Secondary
- **Terracotta** (`colors.terracotta`): light serif headings, actual-set progress and chart line; dark mode uses the lighter copper `colors.dark-secondary`.
- Secondary containers and their paired foregrounds support the floating action treatment and contextual accents. Use `onSecondaryContainer` for the logger's outlined skip action rather than assuming the heading color suits all text.

### Tertiary
- **Tan** (`colors.tan`): authored tertiary role in both modes, paired with forest. Keep this supporting tone subordinate to olive and copper.

### Neutral
- **Cream** (`colors.cream`) and **Forest** (`colors.forest`): light surface/ink and dark ink/surface respectively. App-bar titles use ink; ordinary serif headings use the secondary accent.
- Authored surface-container roles progress from lowest to highest tone in each theme. Inputs use the lowest container; phone navigation uses the low container. Outlines and dividers use their own paired brightness-aware roles.
- Error roles use authored rust in light mode and pale coral in dark mode. Unoverridden Material roles remain derived from the olive seed.

**The Semantic Pairing Rule.** Resolve colors from the active `ColorScheme` and preserve its foreground/background pairings in both themes.

## Typography

**Display Font:** bundled Lora for headline and title-large roles; licensed font assets are included locally.
**Body Font:** native Material sans-serif (Roboto on Android) for controls, ordinary titles, labels and supporting text.

**Character:** warm serif hierarchy above clear practical quantities. Sentence case remains the default; KG and REPS serve as the logger's aligned column headings.

### Hierarchy
- **Headline large:** prominent best-in-range quantity; ink overrides the usual copper heading color.
- **Headline medium:** Stats page heading.
- **Headline small:** logger exercise heading and shared empty-state titles.
- **Title large:** section and plan headings, overview numbers and app-bar titles. Plan names and app bars override copper with ink.
- **Title medium:** ordinary exercise and session titles; set-entry values override this role to 20 sp, weight 600.
- **Body medium / small:** details, saving state, set menu labels and chart labels.
- **Label large:** native action labels; filled buttons override the base size to 16 sp.

The frontmatter records authored overrides and inherited Material 2021 English-like base metrics. Other body/title/label roles retain Material defaults. There is no custom mono face or separate web font stack.

**The Scaling Rule.** Honor system text scaling and scrolling; do not shrink text to force a narrow row.

## Layout

Shared `PageBody` caps content at 840 dp and aligns it at the top. Main pages use 20 dp gutters. Gaps of 4–12 dp group related information; 16–24 dp separates sections. Empty states use 32 dp padding. Bodies respect `SafeArea` and scroll as content grows.

Below 700 dp the three destinations use bottom navigation; wider layouts use a labelled rail. Catalogue search and filters stay above the list; filters stack when `textScaler.scale(14) > 16`. The catalogue reserves 100 dp bottom clearance for its floating action. Plan save stays in the existing padded bottom area.

Logger headers and fields share column alignment: a 56 dp leading reservation, equal expanded KG/REPS columns with a 12 dp gap, and a 56 dp trailing reservation. Actual rows use 48 dp set-options and completion controls with 8 dp adjacent gaps. Add set, Skip/Resume exercise, saving state and Back to workout stack below the table at full width. Last-time information stays in an expandable tonal strip above entry.

Stats keeps compact date-range selection, two equal number-first totals, compact exercise selection and contiguous metric segments in one flow. A prominent best value and 180 dp chart precede exact records and expandable overview details. Long selector values use the available field width; exercise names ellipsize in the selector. Dates retain locale formatting and native date pickers.

## Elevation & Depth

Depth is primarily tonal and outlined. Plan and exercise containers stay flat; resume and totals use filled roles without authored shadows. The floating action theme has 1 dp elevation. Menus, dialogs, route transitions, ripple feedback and state layers remain native Material behavior. No custom CSS shadow or motion vocabulary belongs to the application.

## Shapes

Soft rectangular forms keep the logbook practical: fields and totals use 10 dp corners, outlined plan/exercise containers and themed filled/outlined buttons use 12 dp, resume uses 16 dp, and metric segments and progress bars use 8 dp. Text buttons, dialogs, navigation indicators and remaining Material controls retain their native shapes. Borders organize related content without turning every history record into a separate card.

## Components

### Buttons

Olive filled actions mark Start, Review and Back to workout. Themed filled buttons use 12 dp corners and a minimum 48-by-52 dp target; outlined and text buttons have a minimum 48-by-48 dp target. Add set uses the primary container pair. Skip/Resume exercise uses a secondary outline and `onSecondaryContainer` text. Native disabled, hover, pressed and keyboard-focus feedback remains intact.

### Chips and metric segments

Catalogue filters retain native controls. Stats uses one contiguous native `SegmentedButton`, not wrapped metric chips: selected olive/on-primary, unselected primary-container/on-surface, outline-variant borders, 8 dp outer shape and 48 dp minimum height. Weighted exercises offer Weight, Reps, Sets and Volume; bodyweight exercises offer Reps and Sets. The selected fill indicates state without an extra check icon.

### Cards / Containers

Plans and workout exercises use flat outlined 12 dp containers. Plan cards use 16 dp padding, serif ink names, separate exercise preview lines and a full-width Start/Resume action. Resume uses primary/on-primary with 16 dp corners and padding. Stats totals are equal-width primary-container tiles, 10 dp corners and 12 dp padding, with the number above its label. Last time uses an expandable primary-container strip with 10 dp corners.

### Inputs / Fields

Native filled outlined fields use lowest-container fill, semantic outlines, 10 dp corners and 16 dp themed padding. The logger centers numeric values with 8-by-12 dp padding and non-floating accessible Weight/Reps labels beneath the aligned unit headers. Stats selectors use compact 14-by-12 dp padding and non-floating labels. Validation, numeric keyboard navigation, focus and disabled treatments stay native. Search retains its label and search icon.

### Navigation

Workouts, History and Stats use native destinations with outlined default icons and filled selected icons. The phone bar uses the low surface container and primary-container indicator, with zero authored elevation. Wide layouts use a labelled rail. Detail pages retain named app bars, back navigation, tooltips and established destructive confirmations.

### Any-order checklist and compact set logger

Workout rows are unnumbered and directly tappable. Untouched, partial, completed and skipped statuses use distinct icons and text. Completion counts and a copper actual-set progress bar describe recorded progress. Review workout remains a full-width olive action. There is no Next exercise action.

The compact logger repeats numbered sets in aligned KG/REPS columns. Each set's leading menu contains Remove set; its trailing checkbox has an explicit completion semantic label. Completing validates kg and reps; valid entries autosave locally. Last-time expansion exposes the contextual copy action. Saving/error feedback and Back to workout remain visible in the same scroll flow.

### Recorded progress

Stats follows the approved chart-led hierarchy. Its native contiguous metric selection sits beneath the exercise selector; best-in-range and latest change lead into a 180 dp chart with a 3 dp copper line, straight segments, visible points and horizontal outline-variant grid. Dates flank the chart below. The chart has a semantic description and exact session values below it, so the plot is not the only representation. Empty ranges provide actionable text rather than fabricated data.

## Do's and Don'ts

### Do:
- **Do** use brightness-aware semantic roles and the locally bundled Lora headings.
- **Do** preserve aligned numeric columns, equal Stats totals and contiguous native metric segments.
- **Do** keep related entry actions and previous-workout information in the logger workflow.
- **Do** support any-order exercise choice, text scaling, native focus and scrolling.
- **Do** check light/dark, compact/wide, enlarged text, keyboard access and crowded records before completion.

### Don't:
- **Don't** restore the obsolete blue identity or replace the approved serif headings with condensed capitals.
- **Don't** impose exercise sequence or show a Next exercise action.
- **Don't** substitute wrapped metric chips or oversized selectors for the approved compact Stats composition.
- **Don't** replace native state feedback, validation or accessible labels with decorative controls.
- **Don't** present sample review records as personal history or browser illustrations as shipping Flutter widgets.
