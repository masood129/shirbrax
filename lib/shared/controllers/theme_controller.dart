import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirbrax/core/storage/local_storage.dart';

/// Controls light/dark theme toggle — persisted to storage
class ThemeController extends GetxController {
  final _isDark = false.obs;

  bool get isDark => _isDark.value;
  ThemeMode get themeMode => _isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _isDark.value = LocalStorage.isDarkMode;
  }

  void toggle() {
    _isDark.value = !_isDark.value;
    LocalStorage.setDarkMode(_isDark.value);
    Get.changeThemeMode(_isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  void setDark(bool value) {
    _isDark.value = value;
    LocalStorage.setDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
}
