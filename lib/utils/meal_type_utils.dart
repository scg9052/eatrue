// lib/utils/meal_type_utils.dart
// 식단 타입 관련 유틸리티 함수 모음
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 카테고리 목록 - 영어
final List<String> englishCategories = ['breakfast', 'lunch', 'dinner', 'snacks', 'other'];

/// 식사 유형별 아이콘
IconData getMealTypeIcon(String mealType) {
  final type = mealType.toLowerCase();
  switch (type) {
    case 'breakfast':
      return Icons.breakfast_dining;
    case 'lunch':
      return Icons.lunch_dining;
    case 'dinner':
      return Icons.dinner_dining;
    case 'snack':
    case 'snacks':
      return Icons.icecream;
    default:
      return Icons.restaurant;
  }
}

/// 영어 카테고리 이름을 현재 언어의 카테고리 이름으로 변환
String getLocalizedCategory(String englishCategory, BuildContext context) {
  final localization = AppLocalizations.of(context);
  
  switch (englishCategory.toLowerCase()) {
    case 'breakfast':
      return localization.breakfast;
    case 'lunch':
      return localization.lunch;
    case 'dinner':
      return localization.dinner;
    case 'snack':
    case 'snacks':
      return localization.snack;
    default:
      return englishCategory;
  }
}

/// 현지화된 카테고리 이름에서 영어 카테고리 이름으로 변환
String getEnglishCategory(String localizedCategory, BuildContext context) {
  final localization = AppLocalizations.of(context);
  
  if (localizedCategory == localization.breakfast) {
    return 'breakfast';
  } else if (localizedCategory == localization.lunch) {
    return 'lunch';
  } else if (localizedCategory == localization.dinner) {
    return 'dinner';
  } else if (localizedCategory == localization.snack) {
    return 'snack';
  } else {
    // 기존 한글/영어 매핑을 폴백으로 사용
    return _legacyCategoryToEnglish(localizedCategory);
  }
}

/// 기존 한글 카테고리명을 영어로 변환 (하위 호환성 유지)
String _legacyCategoryToEnglish(String koreanCategory) {
  final Map<String, String> koreanToEnglish = {
    '아침': 'breakfast',
    '점심': 'lunch',
    '저녁': 'dinner',
    '간식': 'snacks',
    '기타': 'other'
  };
  
  return koreanToEnglish[koreanCategory] ?? 'other';
}

/// 기존 영어 카테고리명을 한글로 변환 (하위 호환성 유지)
String _legacyCategoryToKorean(String englishCategory) {
  final Map<String, String> englishToKorean = {
    'breakfast': '아침',
    'lunch': '점심',
    'dinner': '저녁',
    'snacks': '간식',
    'snack': '간식',
    'other': '기타'
  };
  
  return englishToKorean[englishCategory.toLowerCase()] ?? '기타';
}

/// 카테고리가 유효한지 확인하는 함수
bool isValidCategory(String category, {BuildContext? context}) {
  // 영어 카테고리 확인
  if (englishCategories.contains(category.toLowerCase())) {
    return true;
  }
  
  // 컨텍스트가 있는 경우 지역화된 카테고리 이름도 확인
  if (context != null) {
    final localization = AppLocalizations.of(context);
    final localizedCategories = [
      localization.breakfast,
      localization.lunch,
      localization.dinner,
      localization.snack,
      'other'
    ];
    
    if (localizedCategories.contains(category)) {
      return true;
    }
  }
  
  return false;
}

// 하위 호환성을 위한 함수들
String getKoreanMealCategory(String englishCategory) {
  return _legacyCategoryToKorean(englishCategory);
}

String getEnglishMealCategory(String koreanCategory) {
  return _legacyCategoryToEnglish(koreanCategory);
}

/// 카테고리 표준화 함수 (어떤 형식이든 적절한 형식으로 변환)
String standardizeCategory(String category, {bool toKorean = true}) {
  // 영어 카테고리인 경우
  if (['breakfast', 'lunch', 'dinner', 'snack', 'snacks', 'other'].contains(category.toLowerCase())) {
    return toKorean ? _legacyCategoryToKorean(category.toLowerCase()) : category.toLowerCase();
  }
  
  // 한글 카테고리인 경우
  if (['아침', '점심', '저녁', '간식', '기타'].contains(category)) {
    return toKorean ? category : _legacyCategoryToEnglish(category);
  }
  
  // 유효하지 않은 카테고리
  return toKorean ? '기타' : 'other';
} 