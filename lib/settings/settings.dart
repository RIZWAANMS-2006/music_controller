import 'package:Rusic/managers/ui_manager.dart';
import 'package:Rusic/managers/credentials_manager.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:Rusic/settings/server_screens/server_configuration_screen.dart';
import 'package:Rusic/settings/supabase_screens/supabase_configuration_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final GlobalKey<NavigatorState> _settingsNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _settingsNavigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            return _buildSettings(context);
          },
        );
      },
    );
  }

  Widget _buildSettings(BuildContext context) {
    // Both views are unified under _UnifiedSettingsScreen which handles
    // the layout changes internally below.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  stretch: true,
                  alwaysShowMiddle: false,
                  border: Border(
                    bottom: BorderSide(color: setAppBarBorderColor(context)),
                  ),
                  backgroundColor: setAppBarColor(context),
                  largeTitle: const Text("Settings"),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
                  sliver: SliverToBoxAdapter(child: UnifiedSettingsScreen()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          // 1. Clear FlutterSecureStorage
                          final credentialsManager = CredentialsManager();
                          await credentialsManager.clearAll();

                          // 2. Clear SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          if (context.mounted) {
                            showToast(
                              context,
                              "All app data has been cleared.",
                            );
                          }
                        },
                        child: const Text("Clear All App Data"),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                // decoration: BoxDecoration(
                  // gradient: LinearGradient(
                  //   colors: [
                  //     Theme.of(
                  //       context,
                  //     ).scaffoldBackgroundColor.withValues(alpha: 0.0),
                  //     Theme.of(
                  //       context,
                  //     ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                  //     Theme.of(context).scaffoldBackgroundColor,
                  //   ],
                  //   begin: Alignment.topCenter,
                  //   end: Alignment.bottomCenter,
                  // ),
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnifiedSettingsScreen extends StatefulWidget {
  const UnifiedSettingsScreen({super.key});

  @override
  State<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends State<UnifiedSettingsScreen> {
  static const List<String> _fontOptions = [
    SettingsManager.defaultFontFamily,
    'ComicRelief',
    SettingsManager.systemFontOption,
  ];

  static const List<DropdownMenuEntry<String>> _fontDropdownEntries = [
    DropdownMenuEntry(value: 'Asimovian', label: 'Asimovian'),
    DropdownMenuEntry(value: 'ComicRelief', label: 'ComicRelief'),
    DropdownMenuEntry(value: 'System Font', label: 'System Font'),
  ];

  final CredentialsManager _credentialsManager = CredentialsManager();

  late TextEditingController highlightsDurationController;
  late TextEditingController skipAtBeginningController;
  late TextEditingController skipAtEndController;
  late FocusNode highlightsDurationFocusNode;
  late FocusNode skipAtBeginningFocusNode;
  late FocusNode skipAtEndFocusNode;

  late String _selectedSystemTheme;
  late String _selectedAppUi;
  late String _selectedVideoPreference;
  late String _selectedFont;
  late double _crossFade;
  late bool _playHighlights;
  List<Map<String, String>> _supabaseConfigs = [];
  List<Map<String, String>> _serverConfigs = [];

  @override
  void initState() {
    super.initState();
    _selectedSystemTheme = SettingsManager.getSystemTheme;
    _selectedAppUi = SettingsManager.getAppUI;
    _selectedVideoPreference = SettingsManager.getVideoPreference;
    _selectedFont = _normalizeFont(SettingsManager.getFontFamily);
    _crossFade = SettingsManager.getCrossfadeDuration;
    _playHighlights = SettingsManager.getPlayHighlights;

    highlightsDurationController = TextEditingController(
      text: SettingsManager.getHighlightsDuration,
    );
    skipAtBeginningController = TextEditingController(
      text: SettingsManager.getSkipAtBeginning,
    );
    skipAtEndController = TextEditingController(
      text: SettingsManager.getSkipAtEnd,
    );
    highlightsDurationFocusNode = FocusNode();
    skipAtBeginningFocusNode = FocusNode();
    skipAtEndFocusNode = FocusNode();

    _loadConfigurations();

    highlightsDurationFocusNode.addListener(() {
      if (!highlightsDurationFocusNode.hasFocus) {
        if (highlightsDurationController.text.isNotEmpty) {
          int value = int.tryParse(highlightsDurationController.text) ?? 0;
          if (value < 10) value = 10;
          if (value > 60) value = 60;
          highlightsDurationController.text = value.toString();
          SettingsManager.setHighlightsDuration(value.toString());
        }
      }
    });

    skipAtBeginningFocusNode.addListener(() {
      if (!skipAtBeginningFocusNode.hasFocus) {
        if (skipAtBeginningController.text.isNotEmpty) {
          int value = int.tryParse(skipAtBeginningController.text) ?? 0;
          if (value < 0) value = 0;
          if (value > 10) value = 10;
          skipAtBeginningController.text = value.toString();
          SettingsManager.setSkipAtBeginning(value.toString());
        }
      }
    });

    skipAtEndFocusNode.addListener(() {
      if (!skipAtEndFocusNode.hasFocus) {
        if (skipAtEndController.text.isNotEmpty) {
          int value = int.tryParse(skipAtEndController.text) ?? 0;
          if (value < 0) value = 0;
          if (value > 10) value = 10;
          skipAtEndController.text = value.toString();
          SettingsManager.setSkipAtEnd(value.toString());
        }
      }
    });
  }

  String _normalizeFont(String font) {
    if (_fontOptions.contains(font)) {
      return font;
    }
    return SettingsManager.defaultFontFamily;
  }

  void _onSystemThemeChanged(String? value) {
    final selectedTheme = value ?? 'System';
    setState(() {
      _selectedSystemTheme = selectedTheme;
    });
    SettingsManager.setSystemTheme(selectedTheme);
  }

  void _onFontChanged(String? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedFont = value;
    });
    SettingsManager.setFontFamily(value);
  }

  void _onAppUiChanged(String value) {
    setState(() {
      _selectedAppUi = value;
    });
    SettingsManager.setAppUI(value);
  }

  void _onVideoPreferenceChanged(String value) {
    setState(() {
      _selectedVideoPreference = value;
    });
    SettingsManager.setVideoPreference(value);
  }

  void _onCrossFadeChanged(double value) {
    setState(() {
      _crossFade = value;
    });
    SettingsManager.setCrossfadeDuration(value);
  }

  void _onPlayHighlightsChanged(bool value) {
    setState(() {
      _playHighlights = value;
    });
    SettingsManager.setPlayHighlights(value);
  }

  Widget _controlLabel(String text) {
    return Text(text);
  }

  Map<String, Widget> get _systemThemeOptions => {
    "System": _controlLabel("System"),
    "Light": _controlLabel("Light"),
    "Dark": _controlLabel("Dark"),
  };

  Future<void> _loadConfigurations() async {
    final supaConfigs = await _credentialsManager.getSupabaseConfigurations();
    final srvConfigs = await _credentialsManager.getServerConfigurations();

    if (mounted) {
      setState(() {
        _supabaseConfigs = supaConfigs;
        _serverConfigs = srvConfigs;
      });
    }
  }

  @override
  void dispose() {
    highlightsDurationController.dispose();
    highlightsDurationFocusNode.dispose();
    skipAtBeginningController.dispose();
    skipAtBeginningFocusNode.dispose();
    skipAtEndController.dispose();
    skipAtEndFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 700;

    if (isWideScreen) {
      return _buildWide(context);
    } else {
      return _buildCompact(context);
    }
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── System Settings ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("System Settings"),
              const Divider(),
              const SizedBox(height: 16),
              _SettingsRow(
                label: "Font",
                child: DropdownMenu(
                  width: 150,
                  hintText: "Select Font",
                  initialSelection: _selectedFont,
                  textStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownMenuEntries: _fontDropdownEntries,
                  onSelected: _onFontChanged,
                ),
              ),
              const SizedBox(height: 16),
              const Text("System Theme", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Center(
                child: CupertinoSlidingSegmentedControl(
                  children: _systemThemeOptions,
                  groupValue: _selectedSystemTheme,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  isMomentary: false,
                  onValueChanged: _onSystemThemeChanged,
                ),
              ),
              const SizedBox(height: 16),
              const Text("App UI", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: _controlLabel("Minimalistic"),
                      selected: _selectedAppUi == "Minimalistic",
                      onSelected: (_) => _onAppUiChanged("Minimalistic"),
                    ),
                    ChoiceChip(
                      label: _controlLabel("Graphic"),
                      selected: _selectedAppUi == "Graphic",
                      onSelected: (_) => _onAppUiChanged("Graphic"),
                    ),
                    ChoiceChip(
                      label: _controlLabel("Weather Theme"),
                      selected: _selectedAppUi == "Weather Theme",
                      onSelected: (_) => _onAppUiChanged("Weather Theme"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Audio Settings ────────────────────────────────────────────────
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("Audio Settings"),
              const Divider(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Skip at Beginning",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      width: 35,
                      child: TextField(
                        controller: skipAtBeginningController,
                        focusNode: skipAtBeginningFocusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          suffixText: "s",
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => skipAtBeginningFocusNode.unfocus(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Skip at End", style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 35,
                      child: TextField(
                        controller: skipAtEndController,
                        focusNode: skipAtEndFocusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          suffixText: "s",
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => skipAtEndFocusNode.unfocus(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Cross Fade", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16.0,
                  ),
                  valueIndicatorShape: SliderComponentShape.noThumb,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  showValueIndicator: ShowValueIndicator.onDrag,
                ),
                child: Slider(
                  padding: EdgeInsets.zero,
                  value: _crossFade,
                  onChanged: _onCrossFadeChanged,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _crossFade.toInt().toString(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0s",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "10s",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Video Settings ────────────────────────────────────────────────
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("Video Settings"),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                "Video Preference (Default)",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: _controlLabel("Contain"),
                      selected: _selectedVideoPreference == "Contain",
                      onSelected: (_) => _onVideoPreferenceChanged("Contain"),
                    ),
                    ChoiceChip(
                      label: _controlLabel("Cover"),
                      selected: _selectedVideoPreference == "Cover",
                      onSelected: (_) => _onVideoPreferenceChanged("Cover"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsRow(
                label: "Play Highlights (Default)",
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _playHighlights,
                    onChanged: _onPlayHighlightsChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsRow(
                label: "Highlights Duration",
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 35,
                    child: TextField(
                      controller: highlightsDurationController,
                      focusNode: highlightsDurationFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => highlightsDurationFocusNode.unfocus(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        suffixText: "s",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Supabase Configuration",
                        style: TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        onPressed: () {
                          supabaseConfigurationScreenState(context);
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  for (final config in _supabaseConfigs) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            config['tableName'] ?? "Configured",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _credentialsManager
                                .removeSupabaseConfiguration(
                                  config['tableName']!,
                                );
                            await _loadConfigurations();
                            if (context.mounted) {
                              showToast(
                                context,
                                'Supabase configuration cleared',
                              );
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Server Configuration",
                    style: TextStyle(fontSize: 14),
                  ),
                  IconButton(
                    onPressed: () {
                      serverConfigurationScreenState(context);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              for (final config in _serverConfigs) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        config['serverName'] ??
                            config['serverAddress'] ??
                            "Configured",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _credentialsManager.removeServerConfiguration(
                          config['serverName']!,
                        );
                        await _loadConfigurations();
                        if (context.mounted) {
                          showToast(context, 'Server configuration cleared');
                        }
                      },
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── System Settings ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("System Settings"),
              const Divider(),
              const SizedBox(height: 16),
              GridView.extent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 2.2, // Adjusted to fit padded cards nicely
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GridItemCard(
                    child: _SettingsRow(
                      label: "Font",
                      child: DropdownMenu(
                        width: 150,
                        hintText: "Select Font",
                        initialSelection: _selectedFont,
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownMenuEntries: _fontDropdownEntries,
                        onSelected: _onFontChanged,
                      ),
                    ),
                  ),
                  _GridItemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "System Theme",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: CupertinoSlidingSegmentedControl(
                            children: _systemThemeOptions,
                            groupValue: _selectedSystemTheme,
                            thumbColor: Theme.of(context).colorScheme.primary,
                            isMomentary: false,
                            onValueChanged: _onSystemThemeChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GridItemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("App UI", style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: _controlLabel("Minimalistic"),
                                selected: _selectedAppUi == "Minimalistic",
                                onSelected: (_) =>
                                    _onAppUiChanged("Minimalistic"),
                              ),
                              ChoiceChip(
                                label: _controlLabel("Graphic"),
                                selected: _selectedAppUi == "Graphic",
                                onSelected: (_) => _onAppUiChanged("Graphic"),
                              ),
                              ChoiceChip(
                                label: _controlLabel("Weather Theme"),
                                selected: _selectedAppUi == "Weather Theme",
                                onSelected: (_) =>
                                    _onAppUiChanged("Weather Theme"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Audio Settings ────────────────────────────────────────────────
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("Audio Settings"),
              const Divider(),
              const SizedBox(height: 16),
              GridView.extent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 2.2, // Match system settings
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GridItemCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Skip at Beginning",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          width: 35,
                          child: TextField(
                            controller: skipAtBeginningController,
                            focusNode: skipAtBeginningFocusNode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              suffixText: "s",
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                skipAtBeginningFocusNode.unfocus(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GridItemCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Skip at End",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          width: 35,
                          child: TextField(
                            controller: skipAtEndController,
                            focusNode: skipAtEndFocusNode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              suffixText: "s",
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => skipAtEndFocusNode.unfocus(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GridItemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Cross Fade",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16.0,
                              ),
                              valueIndicatorShape: SliderComponentShape.noThumb,
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              showValueIndicator: ShowValueIndicator.onDrag,
                            ),
                            child: Slider(
                              padding: EdgeInsets.zero,
                              value: _crossFade,
                              onChanged: _onCrossFadeChanged,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              label: _crossFade.toInt().toString(),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "0s",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "10s",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Video Settings ────────────────────────────────────────────────
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader("Video Settings"),
              const Divider(),
              const SizedBox(height: 16),
              GridView.extent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 2.2, // Maintain consistency
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GridItemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Video Preference (Default)",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: _controlLabel("Contain"),
                                selected: _selectedVideoPreference == "Contain",
                                onSelected: (_) =>
                                    _onVideoPreferenceChanged("Contain"),
                              ),
                              ChoiceChip(
                                label: _controlLabel("Cover"),
                                selected: _selectedVideoPreference == "Cover",
                                onSelected: (_) =>
                                    _onVideoPreferenceChanged("Cover"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GridItemCard(
                    child: _SettingsRow(
                      label: "Play Highlights (Default)",
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _playHighlights,
                          onChanged: _onPlayHighlightsChanged,
                        ),
                      ),
                    ),
                  ),
                  _GridItemCard(
                    child: _SettingsRow(
                      label: "Highlights Duration",
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 35,
                          child: TextField(
                            controller: highlightsDurationController,
                            focusNode: highlightsDurationFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                highlightsDurationFocusNode.unfocus(),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              suffixText: "s",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Supabase Configuration",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          supabaseConfigurationScreenState(context);
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  GridView.extent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio:
                        4, // Aspect ratio tailored for shorter configuration cards
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final config in _supabaseConfigs)
                        _GridItemCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  config['tableName'] ?? "Configured",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _credentialsManager
                                      .removeSupabaseConfiguration(
                                        config['tableName']!,
                                      );
                                  await _loadConfigurations();
                                  if (context.mounted) {
                                    showToast(
                                      context,
                                      'Supabase configuration cleared',
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Server Configuration",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      serverConfigurationScreenState(context);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              GridView.extent(
                maxCrossAxisExtent: 400,
                childAspectRatio:
                    4, // Consistent configuration card aspect ratio
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final config in _serverConfigs)
                    _GridItemCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              config['serverName'] ??
                                  config['serverAddress'] ??
                                  "Configured",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _credentialsManager
                                  .removeServerConfiguration(
                                    config['serverName']!,
                                  );
                              await _loadConfigurations();
                              if (context.mounted) {
                                showToast(
                                  context,
                                  'Server configuration cleared',
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.remove,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingsRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        child,
      ],
    );
  }
}

void showToast(BuildContext context, String message) {
  toastification.show(
    title: Text(message),
    style: ToastificationStyle.simple,
    autoCloseDuration: const Duration(seconds: 2),
    alignment: Alignment.bottomCenter,
    margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    borderRadius: BorderRadius.circular(30),
    showProgressBar: false,
    type: ToastificationType.info,
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    applyBlurEffect: false,
  );
}

class _GridItemCard extends StatelessWidget {
  final Widget child;

  const _GridItemCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
