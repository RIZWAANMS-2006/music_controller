import "package:shared_preferences/shared_preferences.dart";
import 'package:flutter/material.dart';

class SettingsManager {
  static const String defaultFontFamily = 'Asimovian';
  static const String systemFontOption = 'System Font';

  ThemeData get lightTheme {
    const textColor = Colors.black; // Black text

    return ThemeData(
      fontFamily: _themeFontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 255, 0, 0),
        // seedColor: const Color(0xFFF28D7B), // Coral / warm peach seed
        // surfaceContainerHighest: const Color(0xFFE29F8B), // For cards with 0.3 opacity
      ),
      focusColor: Colors.transparent,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(
        0xFFFDF1E6,
      ), // Pale peach/beige background
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textColor),
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Color.fromRGBO(224, 63, 79, 1),
        colorScheme: ColorScheme.light(primary: Color.fromRGBO(224, 63, 79, 1)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(224, 63, 79, 1),
        ),
      ),
    );
  }

  ThemeData get darkTheme => ThemeData(
    fontFamily: _themeFontFamily,
    brightness: Brightness.dark,
    focusColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color.fromARGB(255, 255, 0, 0),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color.fromRGBO(26, 26, 26, 1),
    ),
    scaffoldBackgroundColor: const Color.fromRGBO(26, 26, 26, 1),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color.fromRGBO(26, 26, 26, 1),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      bodyLarge: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      bodySmall: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      displayLarge: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      displayMedium: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      displaySmall: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      headlineLarge: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      headlineMedium: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      headlineSmall: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      titleLarge: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      titleMedium: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
      titleSmall: TextStyle(color: Color.fromRGBO(255, 245, 245, 1)),
    ),
    iconTheme: const IconThemeData(color: Color.fromRGBO(255, 245, 245, 1)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      iconTheme: IconThemeData(color: Color.fromRGBO(255, 245, 245, 1)),
      titleTextStyle: TextStyle(
        color: Color.fromRGBO(255, 245, 245, 1),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color.fromRGBO(224, 63, 79, 1),
      colorScheme: ColorScheme.dark(primary: Color.fromRGBO(224, 63, 79, 1)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(224, 63, 79, 1),
      ),
    ),
  );

  static late SharedPreferences userSettings;

  static const String _systemThemeKey = 'systemTheme';
  static final ValueNotifier<String> systemTheme = ValueNotifier('System');
  static final ValueNotifier<String> fontFamily = ValueNotifier(
    defaultFontFamily,
  );
  static const String _appUiKey = 'appUI';
  static final ValueNotifier<String> appUI = ValueNotifier('Minimalistic');
  static const String _crossfadeDurationKey = 'crossfadeDuration';
  static final ValueNotifier<double> crossfadeDuration = ValueNotifier(0.0);
  static const String _videoPreferenceKey = 'videoPreference';
  static final ValueNotifier<String> videoPreference = ValueNotifier('Contain');
  static const String _playHighlightsKey = 'playHighlights';
  static final ValueNotifier<bool> playHighlights = ValueNotifier(false);
  static const String _highlightsDurationKey = 'highlightsDuration';
  static final ValueNotifier<String> highlightsDuration = ValueNotifier('30');
  static const String _skipAtBeginningKey = 'skipAtBeginning';
  static final ValueNotifier<String> skipAtBeginning = ValueNotifier('0');
  static const String _skipAtEndKey = 'skipAtEnd';
  static final ValueNotifier<String> skipAtEnd = ValueNotifier('0');
  static const String _fontFamilyKey = 'fontFamily';
  static const String _lastSongPlayedNameKey = 'lastSongPlayedName';
  static const String _lastSongPlayedPathKey = 'lastSongPlayedPath';
  static const String _lastLibraryTabKey = 'lastLibraryTab';

  static Future<void> init() async {
    userSettings = await SharedPreferences.getInstance();
    systemTheme.value = userSettings.getString(_systemThemeKey) ?? 'System';
    fontFamily.value = getFontFamily;
    appUI.value = getAppUI;
    crossfadeDuration.value = getCrossfadeDuration;
    videoPreference.value = getVideoPreference;
    playHighlights.value = getPlayHighlights;
    highlightsDuration.value = getHighlightsDuration;
    skipAtBeginning.value = getSkipAtBeginning;
    skipAtEnd.value = getSkipAtEnd;
  }

  // Get Functions
  static String get getSystemTheme =>
      userSettings.getString(_systemThemeKey) ?? "System";
  static String get getAppUI =>
      userSettings.getString(_appUiKey) ?? "Minimalistic";
  static double get getCrossfadeDuration =>
      userSettings.getDouble(_crossfadeDurationKey) ?? 0.0;
  static String get getVideoPreference =>
      userSettings.getString(_videoPreferenceKey) ?? "Contain";
  static bool get getPlayHighlights =>
      userSettings.getBool(_playHighlightsKey) ?? false;
  static String get getHighlightsDuration =>
      userSettings.getString(_highlightsDurationKey) ?? "30";
  static String get getSkipAtBeginning =>
      userSettings.getString(_skipAtBeginningKey) ?? "0";
  static String get getSkipAtEnd =>
      userSettings.getString(_skipAtEndKey) ?? "0";

  // Previously existing gets
  static String get getFontFamily {
    return _normalizeFontValue(userSettings.getString(_fontFamilyKey));
  }

  String? get _themeFontFamily {
    final family = getFontFamily;
    return family == systemFontOption ? null : family;
  }

  static String get getLastSongPlayedName =>
      userSettings.getString(_lastSongPlayedNameKey) ?? "No Song is Playing...";
  static String get getLastSongPlayedPath =>
      userSettings.getString(_lastSongPlayedPathKey) ?? "";
  static int get getLastLibraryTab =>
      userSettings.getInt(_lastLibraryTabKey) ?? 0;

  // Set Functions
  static Future<void> setSystemTheme(String value) async {
    await userSettings.setString(_systemThemeKey, value);
    systemTheme.value = value;
  }

  static Future<void> setAppUI(String value) async {
    await userSettings.setString(_appUiKey, value);
    appUI.value = value;
  }

  static Future<void> setCrossfadeDuration(double value) async {
    await userSettings.setDouble(_crossfadeDurationKey, value);
    crossfadeDuration.value = value;
  }

  static Future<void> setVideoPreference(String value) async {
    await userSettings.setString(_videoPreferenceKey, value);
    videoPreference.value = value;
  }

  static Future<void> setPlayHighlights(bool value) async {
    await userSettings.setBool(_playHighlightsKey, value);
    playHighlights.value = value;
  }

  static Future<void> setHighlightsDuration(String value) async {
    await userSettings.setString(_highlightsDurationKey, value);
    highlightsDuration.value = value;
  }

  static Future<void> setSkipAtBeginning(String value) async {
    await userSettings.setString(_skipAtBeginningKey, value);
    skipAtBeginning.value = value;
  }

  static Future<void> setSkipAtEnd(String value) async {
    await userSettings.setString(_skipAtEndKey, value);
    skipAtEnd.value = value;
  }

  // Previously existing sets
  static Future<void> setFontFamily(String value) async {
    final normalizedValue = _normalizeFontValue(value);
    await userSettings.setString(_fontFamilyKey, normalizedValue);
    fontFamily.value = normalizedValue;
  }

  static Future<void> setLastSongPlayedName(String value) async {
    await userSettings.setString(_lastSongPlayedNameKey, value);
  }

  static Future<void> setLastSongPlayedPath(String value) async {
    await userSettings.setString(_lastSongPlayedPathKey, value);
  }

  static Future<void> setLastLibraryTab(int value) async {
    await userSettings.setInt(_lastLibraryTabKey, value);
  }

  static Future<void> setDefaults() async {
    await userSettings.setString(_systemThemeKey, "System");
    systemTheme.value = "System";
    await userSettings.setString(_appUiKey, "Minimalistic");
    appUI.value = "Minimalistic";
    await userSettings.setDouble(_crossfadeDurationKey, 0.0);
    crossfadeDuration.value = 0.0;
    await userSettings.setString(_videoPreferenceKey, "Contain");
    videoPreference.value = "Contain";
    await userSettings.setBool(_playHighlightsKey, false);
    playHighlights.value = false;
    await userSettings.setString(_highlightsDurationKey, "30");
    highlightsDuration.value = "30";
    await userSettings.setString(_skipAtBeginningKey, "0");
    skipAtBeginning.value = "0";
    await userSettings.setString(_skipAtEndKey, "0");
    skipAtEnd.value = "0";
    await userSettings.setString(_fontFamilyKey, defaultFontFamily);
    fontFamily.value = defaultFontFamily;
  }

  static String _normalizeFontValue(String? value) {
    if (value == null || value.isEmpty) {
      return defaultFontFamily;
    }
    if (value == 'Calm') {
      return defaultFontFamily;
    }
    if (value == 'normal' || value == systemFontOption) {
      return systemFontOption;
    }
    if (value == 'Comic Relief') {
      return 'ComicRelief';
    }
    const validFonts = <String>{
      defaultFontFamily,
      'ComicRelief',
      systemFontOption,
    };
    return validFonts.contains(value) ? value : defaultFontFamily;
  }
}
