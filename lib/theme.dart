import 'package:flutter/material.dart';

const olive = Color(0xff606c38);
const forest = Color(0xff283618);
const cream = Color(0xfffefae0);
const terracotta = Color(0xffbc6c25);
const tan = Color(0xffdda15e);

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(seedColor: olive, brightness: brightness)
      .copyWith(
        primary: dark ? const Color(0xffbacb8d) : olive,
        onPrimary: dark ? forest : cream,
        primaryContainer: dark
            ? const Color(0xff3f4b29)
            : const Color(0xffeeead2),
        onPrimaryContainer: dark ? cream : forest,
        secondary: dark ? const Color(0xffefb27e) : terracotta,
        onSecondary: dark ? forest : cream,
        secondaryContainer: dark
            ? const Color(0xff58361c)
            : const Color(0xfff6e3c5),
        onSecondaryContainer: dark ? cream : const Color(0xff653814),
        tertiary: tan,
        onTertiary: forest,
        surface: dark ? forest : cream,
        onSurface: cream,
        onSurfaceVariant: dark
            ? const Color(0xffd4d8bd)
            : const Color(0xff515d3c),
        surfaceContainerLowest: dark
            ? const Color(0xff202b13)
            : const Color(0xfffffdf0),
        surfaceContainerLow: dark
            ? const Color(0xff303e20)
            : const Color(0xfffcf8df),
        surfaceContainer: dark
            ? const Color(0xff354324)
            : const Color(0xfff4efd7),
        surfaceContainerHigh: dark
            ? const Color(0xff3d4b2c)
            : const Color(0xffeee8cc),
        surfaceContainerHighest: dark
            ? const Color(0xff465433)
            : const Color(0xffe9e3c5),
        outline: dark ? const Color(0xff9ba77e) : const Color(0xff7b855e),
        outlineVariant: dark
            ? const Color(0xff586544)
            : const Color(0xffd7d7b9),
        error: dark ? const Color(0xffffb4a5) : const Color(0xffa13024),
        shadow: forest,
        scrim: forest,
      )
      .copyWith(onSurface: dark ? cream : forest);
  final base = ThemeData(useMaterial3: true, colorScheme: colors);
  TextStyle serif(TextStyle? style, {Color? color}) => style!.copyWith(
    fontFamily: 'Lora',
    fontWeight: FontWeight.w600,
    color: color ?? colors.secondary,
    letterSpacing: -0.5,
  );
  final text = base.textTheme.copyWith(
    headlineLarge: serif(base.textTheme.headlineLarge),
    headlineMedium: serif(base.textTheme.headlineMedium),
    headlineSmall: serif(base.textTheme.headlineSmall).copyWith(fontSize: 28),
    titleLarge: serif(base.textTheme.titleLarge)
        .copyWith(fontWeight: FontWeight.w700),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    textTheme: text,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: serif(text.titleLarge, color: colors.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        textStyle: text.labelLarge!.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.secondaryContainer,
      foregroundColor: colors.onSecondaryContainer,
      shape: shape,
      elevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainerLow,
      indicatorColor: colors.primaryContainer,
      elevation: 0,
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: colors.primary,
      checkmarkColor: colors.onPrimary,
      labelStyle: TextStyle(color: colors.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant, thickness: 1),
  );
}
