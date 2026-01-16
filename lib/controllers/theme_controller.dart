import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class ThemeController extends GetxController {
  static const String _keyDarkMode = 'is_dark_mode';
  final _isDarkMode = false.obs;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = _prefs.getBool(_keyDarkMode) ?? false;
    _applyTheme();
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _prefs.setBool(_keyDarkMode, _isDarkMode.value);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    Get.changeTheme(
      _isDarkMode.value ? AppTheme.blackGolden : AppTheme.whiteGolden,
    );
  }
}
