// lib/utils/meal_type_utils.dart
// 식단 타입 관련 유틸리티 함수 모음
import 'package:flutter/material.dart';

/// 카테고리 목록 - 영어
final List<String> englishCategories = ['breakfast', 'lunch', 'dinner', 'snacks', 'other'];

/// 카테고리 목록 - 한글
final List<String> koreanCategories = ['아침', '점심', '저녁', '간식', '기타'];

/// 카테고리 매핑 - 영어 -> 한글
final Map<String, String> englishToKorean = {
  'breakfast': '아침',
  'lunch': '점심',
  'dinner': '저녁',
  'snacks': '간식',
  'snack': '간식',
  'other': '기타'
};

/// 카테고리 매핑 - 한글 -> 영어
final Map<String, String> koreanToEnglish = {
  '아침': 'breakfast',
  '점심': 'lunch',
  '저녁': 'dinner',
  '간식': 'snacks',
  '기타': 'other'
};

/// 한글 식사 카테고리명을 영어로 변환
String getEnglishMealCategory(String koreanCategory) {
  return koreanToEnglish[koreanCategory] ?? 'other';
}

/// 영어 식사 카테고리명을 한글로 변환
String getKoreanMealCategory(String englishCategory) {
  return englishToKorean[englishCategory.toLowerCase()] ?? '기타';
}

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

/// 카테고리가 유효한지 확인하는 함수
bool isValidCategory(String category) {
  // 영어 카테고리 확인
  if (englishCategories.contains(category.toLowerCase())) {
    return true;
  }
  
  // 한글 카테고리 확인
  if (koreanCategories.contains(category)) {
    return true;
  }
  
  return false;
}

/// 카테고리 표준화 함수 (어떤 형식이든 적절한 형식으로 변환)
String standardizeCategory(String category, {bool toKorean = true}) {
  // 영어 카테고리인 경우
  if (englishToKorean.containsKey(category.toLowerCase())) {
    return toKorean ? englishToKorean[category.toLowerCase()]! : category.toLowerCase();
  }
  
  // 한글 카테고리인 경우
  if (koreanToEnglish.containsKey(category)) {
    return toKorean ? category : koreanToEnglish[category]!;
  }
  
  // 유효하지 않은 카테고리
  return toKorean ? '기타' : 'other';
} 