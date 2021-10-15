import 'package:flutter/material.dart';

class ThemeUtils {
  ThemeUtils(this.context);
  final BuildContext context;

  ShapeBorder get shape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );

  PageTransitionsTheme get pageTheme => PageTransitionsTheme(builders: {
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      });

  static ThemeData get _baseDark => ThemeData(
        brightness: Brightness.dark,
      );

  static ThemeData get _baseLight => ThemeData(
        brightness: Brightness.light,
      );

  ThemeData get light => _baseLight.copyWith(
        brightness: Brightness.light,
        cardTheme: CardTheme(shape: shape),
        backgroundColor: Colors.grey.shade700,
        visualDensity: VisualDensity.compact,
        pageTransitionsTheme: pageTheme,
        appBarTheme: dark.appBarTheme,
        bottomAppBarTheme:
            BottomAppBarTheme(color: ThemeData.light().scaffoldBackgroundColor),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.black,
        ),
        primaryColor: Colors.black,
        accentColor: Colors.red,
      );

  ThemeData get dark => _baseDark.copyWith(
        brightness: Brightness.dark,
        cardTheme: CardTheme(color: Colors.black, shape: shape),
        appBarTheme: AppBarTheme(elevation: 0),
        visualDensity: VisualDensity.compact,
        pageTransitionsTheme: pageTheme,
        primaryColor: Colors.black,
        accentColor: ThemeData.dark().accentColor,
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.black),
        backgroundColor: Colors.grey.shade700,
        bottomAppBarColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      );

  ThemeData get themeData => Theme.of(context);
  bool get isDark => themeData.brightness == Brightness.dark;
  Color get firstColor => isDark ? Colors.black : Colors.white;
  Color get secondColor =>
      firstColor.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
}
