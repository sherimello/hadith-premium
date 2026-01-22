import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _keyFontSize = 'font_size';
  static const String _keyShowEnglish = 'show_english';

  final RxDouble fontSize = 16.0.obs;
  final RxBool showEnglish = true.obs;

  late SharedPreferences _prefs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    fontSize.value = _prefs.getDouble(_keyFontSize) ?? 16.0;
    showEnglish.value = _prefs.getBool(_keyShowEnglish) ?? true;
  }

  Future<void> updateFontSize(double size) async {
    fontSize.value = size;
    await _prefs.setDouble(_keyFontSize, size);
  }

  Future<void> toggleEnglish(bool value) async {
    showEnglish.value = value;
    await _prefs.setBool(_keyShowEnglish, value);
  }
}
