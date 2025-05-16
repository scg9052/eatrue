import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/menu_generation_service.dart';
import '../providers/meal_provider.dart';
import '../services/template_service.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = Locale('ko', 'KR');
  static const String PREFS_LANGUAGE_CODE = 'language_code';
  static const String PREFS_COUNTRY_CODE = 'country_code';
  
  MenuGenerationService? _menuGenerationService;
  MealProvider? _mealProvider;
  final TemplateService _templateService = TemplateService();

  LanguageProvider() {
    _loadFromPrefs();
  }

  void setMenuGenerationService(MenuGenerationService service) {
    _menuGenerationService = service;
  }

  void setMealProvider(MealProvider provider) {
    _mealProvider = provider;
  }

  Locale get currentLocale => _currentLocale;
  
  /// 현재 언어 코드를 반환합니다. 
  /// 확장성을 위해 추가된 메서드로, 더 많은 언어를 지원할 때도 유연하게 대응할 수 있습니다.
  String getLanguageCode() {
    return _currentLocale.languageCode;
  }

  void setLocale(Locale locale) {
    if (locale == _currentLocale) return;
    
    final previousLocale = _currentLocale;
    _currentLocale = locale;
    _saveToPrefs();
    
    // 템플릿 서비스 언어 설정 업데이트
    _templateService.setLanguageCode(_currentLocale.languageCode);
    
    if (_menuGenerationService != null) {
      print("언어가 ${previousLocale.languageCode}에서 ${locale.languageCode}로 변경되었습니다. 메뉴 캐시를 초기화합니다.");
      _menuGenerationService!.clearCacheOnLanguageChange();
    }
    
    if (_mealProvider != null) {
      print("언어 변경으로 생성된 메뉴 목록을 초기화합니다.");
      _mealProvider!.clearGeneratedMenus();
    }
    
    notifyListeners();
  }

  // 영어로 변경
  void setEnglish() {
    print("===== 언어 설정을 영어(en)로 변경합니다 =====");
    setLocale(Locale('en', 'US'));
  }

  // 한국어로 변경
  void setKorean() {
    print("===== 언어 설정을 한국어(ko)로 변경합니다 =====");
    setLocale(Locale('ko', 'KR'));
  }

  // 설정된 언어가 한국어인지 확인 (기존 코드 유지. 하위 호환성 위함)
  bool isKorean() {
    bool result = _currentLocale.languageCode == 'ko';
    print("언어 확인: 현재 언어 코드는 ${_currentLocale.languageCode}, 한국어 여부: $result");
    return result;
  }

  // SharedPreferences에 언어 설정 저장
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFS_LANGUAGE_CODE, _currentLocale.languageCode);
      await prefs.setString(PREFS_COUNTRY_CODE, _currentLocale.countryCode ?? '');
      print("언어 설정이 SharedPreferences에 저장되었습니다: ${_currentLocale.languageCode}, ${_currentLocale.countryCode}");
    } catch (e) {
      print("언어 설정 저장 중 오류 발생: $e");
    }
  }

  // SharedPreferences에서 언어 설정 로드
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(PREFS_LANGUAGE_CODE);
      final countryCode = prefs.getString(PREFS_COUNTRY_CODE);
      
      print("SharedPreferences에서 로드된 언어 설정: $languageCode, $countryCode");
      
      if (languageCode != null) {
        _currentLocale = Locale(languageCode, countryCode);
        
        // 템플릿 서비스 언어 설정 업데이트
        _templateService.setLanguageCode(languageCode);
        
        print("언어 설정이 로드되었습니다: ${_currentLocale.languageCode}, ${_currentLocale.countryCode}");
        notifyListeners();
      } else {
        print("저장된 언어 설정이 없어 기본값(한국어)을 사용합니다");
        
        // 템플릿 서비스 언어 설정 업데이트 (기본값: ko)
        _templateService.setLanguageCode('ko');
      }
    } catch (e) {
      print("언어 설정 로드 중 오류 발생: $e");
    }
  }
} 