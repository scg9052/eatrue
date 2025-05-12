// lib/utils/meal_type_utils.dart
// 식단 타입 관련 유틸리티 함수 모음
import 'package:flutter/material.dart';

/// 한글 식사 카테고리명을 영어로 변환
String getEnglishMealCategory(String koreanCategory) {
  switch (koreanCategory) {
    case '아침':
      return 'breakfast';
    case '점심':
      return 'lunch';
    case '저녁':
      return 'dinner';
    case '간식':
      return 'snacks';
    default:
      return 'other';
  }
}

/// 영어 식사 카테고리명을 한글로 변환
String getKoreanMealCategory(String englishCategory) {
  final category = englishCategory.toLowerCase();
  switch (category) {
    case 'breakfast':
      return '아침';
    case 'lunch':
      return '점심';
    case 'dinner':
      return '저녁';
    case 'snacks':
    case 'snack':
      return '간식';
    default:
      return '기타';
  }
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

/// 간단한 영어 메뉴 이름을 한국어로 변환하는 함수
String translateMenuName(String englishName) {
  // 자주 사용되는 메뉴 이름 매핑
  final Map<String, String> menuTranslations = {
    // 아침
    'Scrambled Eggs': '스크램블 에그',
    'Oatmeal': '오트밀',
    'Yogurt': '요거트',
    'Granola': '그래놀라',
    'Toast': '토스트',
    'Pancakes': '팬케이크',
    'Waffles': '와플',
    
    // 점심
    'Salad': '샐러드',
    'Sandwich': '샌드위치',
    'Soup': '수프',
    'Bowl': '볼',
    'Wrap': '랩',
    'Pasta': '파스타',
    'Rice': '밥',
    'Noodles': '국수',
    
    // 저녁
    'Chicken': '닭고기',
    'Beef': '소고기',
    'Fish': '생선',
    'Salmon': '연어',
    'Pork': '돼지고기',
    'Tofu': '두부',
    'Vegetable': '채소',
    'Stir-fry': '볶음',
    'Curry': '카레',
    'Stew': '스튜',
    
    // 간식
    'Fruit': '과일',
    'Nuts': '견과류',
    'Cottage Cheese': '코티지 치즈',
    'Hard-Boiled Eggs': '삶은 계란',
    'Apple': '사과',
    'Banana': '바나나',
    'Peanut Butter': '땅콩 버터',
  };
  
  // 영어 메뉴 이름을 한국어로 변환
  String koreanName = englishName;
  
  // 여러 단어가 포함된 메뉴는 각 단어를 번역하고 결합
  for (var englishWord in menuTranslations.keys) {
    if (englishName.contains(englishWord)) {
      koreanName = koreanName.replaceAll(englishWord, menuTranslations[englishWord]!);
    }
  }
  
  // 번역 후에도 영어가 주로 남아있다면 원래 이름 반환
  int koreanCharCount = 0;
  for (int i = 0; i < koreanName.length; i++) {
    if (koreanName.codeUnitAt(i) > 127) koreanCharCount++;
  }
  
  // 50% 이상 영어면 원래 영어 이름 사용
  if (koreanCharCount < koreanName.length * 0.5) {
    return englishName;
  }
  
  return koreanName;
} 