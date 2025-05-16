import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  static const String LIGHT_MODE = 'light';
  static const String DARK_MODE = 'dark';
  static const String SYSTEM_MODE = 'system';
  
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  ThemeProvider() {
    loadTheme();
  }
  
  // 테마 모드 로드
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String themeString = prefs.getString(THEME_KEY) ?? LIGHT_MODE;
    
    switch (themeString) {
      case DARK_MODE:
        _themeMode = ThemeMode.dark;
        break;
      case SYSTEM_MODE:
        _themeMode = ThemeMode.system;
        break;
      case LIGHT_MODE:
      default:
        _themeMode = ThemeMode.light;
        break;
    }
    
    notifyListeners();
  }
  
  // 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    
    switch (mode) {
      case ThemeMode.dark:
        themeString = DARK_MODE;
        break;
      case ThemeMode.system:
        themeString = SYSTEM_MODE;
        break;
      case ThemeMode.light:
      default:
        themeString = LIGHT_MODE;
        break;
    }
    
    await prefs.setString(THEME_KEY, themeString);
  }
  
  // 다크 모드로 설정
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  // 라이트 모드로 설정
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }
  
  // 시스템 모드로 설정
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
} 