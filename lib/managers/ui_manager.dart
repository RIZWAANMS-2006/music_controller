import 'package:flutter/material.dart';

final ValueNotifier<bool> wideScreenPanelsSwapped = ValueNotifier<bool>(false);

void toggleWideScreenPanels() {
  wideScreenPanelsSwapped.value = !wideScreenPanelsSwapped.value;
}

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color setContainerColor(BuildContext context) {
  return isDarkMode(context)
      ? const Color.fromRGBO(34, 34, 34, 1)
      : const Color.fromRGBO(255, 245, 245, 1);
}

Color setContainerContrastColor(BuildContext context) {
  return isDarkMode(context)
      ? const Color.fromRGBO(255, 245, 245, 1)
      : const Color.fromRGBO(34, 34, 34, 1);
}

Color setAppBarColor(BuildContext context) {
  return isDarkMode(context)
      ? const Color.fromRGBO(34, 34, 34, 1)
      : const Color.fromRGBO(246, 246, 246,1);
}

Color setAppBarBorderColor(BuildContext context) {
  return isDarkMode(context)
      ? Colors.transparent
      : const Color.fromRGBO(206, 206, 206, 1);
}