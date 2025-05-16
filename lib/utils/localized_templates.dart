// 다국어 지원을 위한 템플릿 관리 유틸리티
import 'package:flutter/material.dart';

/// 다국어 템플릿 관리 클래스
/// 여러 언어에 대한 템플릿 문자열을 중앙 집중식으로 관리합니다.
class LocalizedTemplates {
  // 싱글톤 패턴 구현
  static final LocalizedTemplates _instance = LocalizedTemplates._internal();
  factory LocalizedTemplates() => _instance;
  LocalizedTemplates._internal();

  // 사용 가능한 언어 목록
  final List<String> supportedLanguages = ['ko', 'en'];
  
  // 기본 언어 설정
  String defaultLanguage = 'ko';

  // 메뉴 생성 시스템 지시문 템플릿
  Map<String, String> menuSystemInstructionTemplates = {
    'ko': '''
당신은 사용자에게 개인 맞춤형 음식과 식단을 추천하는 영양학 및 식이 전문가입니다.
절대로 한국어로만 응답해야 합니다. 영어로 응답하지 마세요.
반드시 유효한 JSON 형식으로만 응답하세요.
JSON 구문 오류가 발생하지 않도록 각별히 주의하세요.
모든 문자열은 큰따옴표(")로 감싸야 하며, 작은따옴표(')는 사용하지 마세요.
객체와 배열의 마지막 항목 뒤에는 쉼표(,)를 넣지 마세요.
모든 JSON 속성명은 영어 snake_case로 작성하세요(예: dish_name, cooking_time).
코드 블록(```) 또는 설명 없이 순수한 JSON만 반환하세요.
JSON 외에 어떤 텍스트도 포함하지 마세요.
    ''',
    'en': '''
You are a nutrition and diet expert who recommends personalized food and meal plans to users.
You must respond in English only. Do not respond in Korean.
You must respond only in valid JSON format.
Be extremely careful to avoid JSON syntax errors.
All strings must be wrapped in double quotes ("), not single quotes (').
Do not put commas (,) after the last item in objects and arrays.
All JSON property names should be in English snake_case (e.g.: dish_name, cooking_time).
Return pure JSON only, without code blocks (```) or explanations.
Do not include any text outside of the JSON.
    '''
  };

  // 메뉴 생성 재생성 모드 추가 지시문 템플릿
  Map<String, String> menuRegenerationInstructionTemplates = {
    'ko': '''
주의: 이 요청은 이전에 생성된 메뉴를 수정하는 요청입니다.
검증에서 통과한 항목(verificationFeedback에 포함되지 않은 항목)은 그대로 유지하고, 
검증에 실패한 항목(verificationFeedback에 포함된 항목)만 새로운 메뉴로 대체하세요.
    ''',
    'en': '''
Note: This request is to modify a previously generated menu.
Keep items that passed validation (not included in verificationFeedback) as is,
and replace only the items that failed validation (included in verificationFeedback) with new menus.
    '''
  };

  // 메뉴 생성 기본 프롬프트 템플릿
  Map<String, String> menuBasePromptTemplates = {
    'ko': '''
[중요: 반드시 한국어로만 응답하세요]

다음 정보를 바탕으로 하루 식단(아침, 점심, 저녁, 간식)을 생성해주세요.

1) 사용자 권장 영양소: 
{{nutrients}}

2) 사용자 기피 정보: 
{{dislikes}}

3) 사용자 선호 정보: 
{{preferences}}
    ''',
    'en': '''
[IMPORTANT: You must respond in English only]

Please generate a daily meal plan (breakfast, lunch, dinner, snack) based on the following information.

1) Recommended nutrients for the user: 
{{nutrients}}

2) User's food dislikes: 
{{dislikes}}

3) User's food preferences: 
{{preferences}}
    '''
  };

  // 사용자 세부 정보 추가 템플릿
  Map<String, String> userDetailsTemplates = {
    'ko': '''

4) 사용자 상세 정보:
  - 나이: {{age}}
  - 성별: {{gender}}
  - 키: {{height}}
  - 체중: {{weight}}
  - 활동량: {{activityLevel}}
  - 선호 음식: {{favoriteFoods}}
  - 기피 음식: {{dislikedFoods}}
  - 선호 조리법: {{preferredCookingMethods}}
  - 가능한 조리도구: {{availableCookingTools}}
  - 알레르기: {{allergies}}
  - 비건 여부: {{isVegan}}
  - 종교적 제한: {{religionDetails}}
  - 식사 목적: {{mealPurpose}}
  - 예산: {{mealBudget}}
  - 선호하는 조리 시간: {{preferredCookingTime}}
  - 선호 식재료: {{preferredIngredients}}
  - 선호 양념: {{preferredSeasonings}}
  - 선호 조리 스타일: {{preferredCookingStyles}}
  - 기피 식재료: {{dislikedIngredients}}
  - 기피 양념: {{dislikedSeasonings}}
  - 기피 조리 스타일: {{dislikedCookingStyles}}

사용자의 상세 정보를 적극 활용하여 맞춤형 식단을 생성해주세요. 특히 선호/기피 재료와 조리법, 예산, 조리 시간 등을 고려하는 것이 중요합니다.
    ''',
    'en': '''

4) User details:
  - Age: {{age}}
  - Gender: {{gender}}
  - Height: {{height}}
  - Weight: {{weight}}
  - Activity level: {{activityLevel}}
  - Preferred foods: {{favoriteFoods}}
  - Disliked foods: {{dislikedFoods}}
  - Preferred cooking methods: {{preferredCookingMethods}}
  - Available cooking tools: {{availableCookingTools}}
  - Allergies: {{allergies}}
  - Is vegan: {{isVegan}}
  - Religious dietary restrictions: {{religionDetails}}
  - Meal purpose: {{mealPurpose}}
  - Budget: {{mealBudget}}
  - Preferred cooking time: {{preferredCookingTime}}
  - Preferred ingredients: {{preferredIngredients}}
  - Preferred seasonings: {{preferredSeasonings}}
  - Preferred cooking styles: {{preferredCookingStyles}}
  - Disliked ingredients: {{dislikedIngredients}}
  - Disliked seasonings: {{dislikedSeasonings}}
  - Disliked cooking styles: {{dislikedCookingStyles}}

Please use the user's detailed information to create a personalized meal plan. It's especially important to consider preferred/disliked ingredients, cooking methods, budget, and cooking time.
    '''
  };

  // 재생성 정보 템플릿
  Map<String, String> regenerationInfoTemplates = {
    'ko': '''

{{userDetailNumber}}) 이전에 생성된 메뉴:
{{previousMenu}}

{{feedbackNumber}}) 검증 피드백 (재생성이 필요한 항목):
{{verificationFeedback}}

이전 메뉴에서 검증 피드백에 포함된 항목만 새로운 메뉴로 대체하고, 나머지는 그대로 유지하세요.
    ''',
    'en': '''

{{userDetailNumber}}) Previously generated menu:
{{previousMenu}}

{{feedbackNumber}}) Verification feedback (items requiring regeneration):
{{verificationFeedback}}

Replace only the items included in the verification feedback with new menus, and keep the rest as they are.
    '''
  };

  // JSON 출력 형식 지시 템플릿
  Map<String, String> outputFormatInstructionTemplates = {
    'ko': '''

[다시 한번 강조합니다: 반드시 한국어로만 응답하세요]

식단은 다음과 같은 방식으로 생성해주세요:
- 각 식사 카테고리(아침, 점심, 저녁, 간식)별로 정확히 2개의 메뉴만 생성하세요.
- 각 메뉴는 완전한 한 끼 식사를 의미합니다 (주요리와 필요한 반찬이 포함된 형태).
- 건강에 좋고 균형 잡힌 식단을 구성하세요.
- 한국 음식 문화와 계절 식재료를 고려하세요.
- 가능한 한 한국어 메뉴명을 사용하세요.

중요 JSON 작성 지침:
1. 모든 문자열은 큰따옴표(")로 감싸야 합니다. 작은따옴표(')는 사용하지 마세요.
2. 객체와 배열의 마지막 항목 뒤에는 쉼표(,)를 넣지 마세요.
3. 각 필드에 적절한 데이터 타입을 사용하세요:
   - dish_name: 문자열 (예: "비빔밥")
   - category: 문자열 (예: "breakfast", "lunch", "dinner", "snack")
   - description: 문자열 (예: "신선한 야채와 함께...")
   - ingredients: 문자열 배열 (예: ["쌀", "야채", "고추장"])
   - approximate_nutrients: 객체 (예: {"칼로리": "500 kcal", "단백질": "20g"})
   - cooking_time: 문자열 (예: "30분")
   - difficulty: 문자열 (예: "중")
4. JSON 내 모든 값에 유효한 문자열만 사용하세요. 따옴표, 백슬래시 등 특수문자는 이스케이프 처리하세요.
5. 긴 문자열은 중간에 줄바꿈 없이 한 줄로 작성하세요.

다음 JSON 형식을 정확히 따라 응답해주세요:
{
  "breakfast": [
    {
      "dish_name": "메뉴명1",
      "category": "breakfast",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    },
    {
      "dish_name": "메뉴명2",
      "category": "breakfast",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    }
  ],
  "lunch": [
    {
      "dish_name": "메뉴명1",
      "category": "lunch",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    },
    {
      "dish_name": "메뉴명2",
      "category": "lunch",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    }
  ],
  "dinner": [
    {
      "dish_name": "메뉴명1",
      "category": "dinner",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    },
    {
      "dish_name": "메뉴명2",
      "category": "dinner",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "중"
    }
  ],
  "snack": [
    {
      "dish_name": "메뉴명1",
      "category": "snack",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "하"
    },
    {
      "dish_name": "메뉴명2",
      "category": "snack",
      "description": "간단한 설명",
      "ingredients": ["재료1", "재료2", "재료3"],
      "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
      "cooking_time": "XX분",
      "difficulty": "하"
    }
  ]
}
    ''',
    'en': '''

[I EMPHASIZE AGAIN: You must respond in English only]

Please generate the meal plan as follows:
- Generate exactly 2 menus for each meal category (breakfast, lunch, dinner, snack).
- Each menu should represent a complete meal (main dish with necessary side dishes).
- Create a healthy and balanced diet.
- Consider food culture and seasonal ingredients.
- Use appropriate menu names.

Important JSON writing guidelines:
1. All strings must be wrapped in double quotes ("), not single quotes (').
2. Do not put commas (,) after the last item in objects and arrays.
3. Use appropriate data types for each field:
   - dish_name: string (e.g., "Bibimbap")
   - category: string (e.g., "breakfast", "lunch", "dinner", "snack")
   - description: string (e.g., "Fresh vegetables with...")
   - ingredients: string array (e.g., ["rice", "vegetables", "gochujang"])
   - approximate_nutrients: object (e.g., {"calories": "500 kcal", "protein": "20g"})
   - cooking_time: string (e.g., "30 minutes")
   - difficulty: string (e.g., "medium")
4. Use only valid strings within JSON. Escape special characters like quotes and backslashes.
5. Write long strings in a single line without line breaks.

Please follow this JSON format exactly for your response:
{
  "breakfast": [
    {
      "dish_name": "Menu name 1",
      "category": "breakfast",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    },
    {
      "dish_name": "Menu name 2",
      "category": "breakfast",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    }
  ],
  "lunch": [
    {
      "dish_name": "Menu name 1",
      "category": "lunch",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    },
    {
      "dish_name": "Menu name 2",
      "category": "lunch",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    }
  ],
  "dinner": [
    {
      "dish_name": "Menu name 1",
      "category": "dinner",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    },
    {
      "dish_name": "Menu name 2",
      "category": "dinner",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "medium"
    }
  ],
  "snack": [
    {
      "dish_name": "Menu name 1",
      "category": "snack",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "easy"
    },
    {
      "dish_name": "Menu name 2",
      "category": "snack",
      "description": "Brief description",
      "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
      "approximate_nutrients": {"calories": "XXX kcal", "protein": "XX g", "carbohydrates": "XX g", "fat": "XX g"},
      "cooking_time": "XX minutes",
      "difficulty": "easy"
    }
  ]
}
    '''
  };

  // 레시피 생성 시스템 지시문 템플릿
  Map<String, String> recipeSystemInstructionTemplates = {
    'ko': '''
당신은 요리 전문가입니다. 주어진 요리명에 대해 사용자의 선호도와 제한 사항을 고려하여 상세한 레시피를 제공하는 것이 당신의 임무입니다. 레시피에는 요리명, 비용 정보, 영양 정보, 재료와 수량, 양념과 수량, 단계별 조리 방법이 포함되어야 합니다. 절대로 한국어로만 응답해야 합니다. 영어로 응답하지 마세요.
    ''',
    'en': '''
You are a culinary expert. Your task is to provide a detailed recipe for a given dish name, considering user preferences and restrictions. The recipe should include a dish name, cost information, nutritional information, ingredients with quantities, seasonings with quantities, and step-by-step cooking instructions. You must respond in English only. Do not respond in Korean.
    '''
  };

  // 레시피 생성 프롬프트 템플릿
  Map<String, String> recipePromptTemplates = {
    'ko': '''
[중요: 반드시 한국어로만 응답하세요]

다음 요리에 대한 상세 레시피를 생성해주세요: "{{mealName}}"

다음 사용자 정보를 고려하여 개인화해주세요:
* 알레르기: {{allergies}}
* 기피 재료: {{dislikedFoods}}
* 선호 조리법: {{preferredCookingMethods}}
* 사용 가능한 조리도구: {{availableCookingTools}}
* 비건 여부: {{isVegan}}
* 종교적 식이 제한: {{religionDetails}}

레시피는 JSON 형식으로 다음 세부 정보를 포함해야 합니다:
* **dish_name:** 요리명 ("{{mealName}}"이어야 함)
* **cost_information:** 요리 준비에 필요한 예상 비용
* **nutritional_information:** 요리의 영양 성분 분석 (칼로리, 단백질, 탄수화물, 지방은 문자열 형태로, 필요에 따라 비타민, 미네랄은 문자열 배열로 표시)
* **ingredients:** 객체 배열, 각 객체는 "name"(문자열)와 "quantity"(문자열) 포함
* **seasonings:** 객체 배열, 각 객체는 "name"(문자열)와 "quantity"(문자열) 포함
* **cooking_instructions:** 문자열 배열, 각 문자열은 하나의 단계
* **cookingTimeMinutes:** (선택 사항) 예상 조리 시간(분)(정수)
* **difficulty:** (선택 사항) 난이도 수준 (예: "쉬움", "보통", "어려움")

[다시 한번 강조합니다: 반드시 한국어로만 응답하세요]

단일 레시피에 대한 JSON 출력 예시:
{
  "dish_name": "{{mealName}}",
  "cost_information": "약 5천원",
  "nutritional_information": {
    "calories": "350",
    "protein": "30g",
    "carbohydrates": "15g",
    "fats": "18g"
  },
  "ingredients": [
    {"name": "{{mealName}}의 주 재료", "quantity": "1인분"}
  ],
  "seasonings": [
    {"name": "기본 양념", "quantity": "적당량"}
  ],
  "cooking_instructions": [
    "{{mealName}}을 위한 1단계",
    "{{mealName}}을 위한 2단계"
  ],
  "cookingTimeMinutes": 25,
  "difficulty": "보통"
}

이 하나의 레시피를 나타내는 단일 JSON 객체가 출력되도록 해주세요.
    ''',
    'en': '''
[IMPORTANT: You must respond in English only]

Generate a detailed recipe for the following dish: "{{mealName}}".

Please consider these user details for personalization:
* Allergies: {{allergies}}
* Disliked Ingredients: {{dislikedFoods}}
* Preferred Cooking Methods: {{preferredCookingMethods}}
* Available Cooking Tools: {{availableCookingTools}}
* Is Vegan: {{isVegan}}
* Religious Dietary Restrictions: {{religionDetails}}

The recipe should include the following details in JSON format:
* **dish_name:** The name of the dish (should be "{{mealName}}").
* **cost_information:** An estimated cost to prepare the dish.
* **nutritional_information:** A breakdown of the dish's nutritional content (calories, protein, carbohydrates, fats as strings, and optionally vitamins, minerals as lists of strings).
* **ingredients:** A list of objects, each with "name" (string) and "quantity" (string).
* **seasonings:** A list of objects, each with "name" (string) and "quantity" (string).
* **cooking_instructions:** A list of strings, where each string is a step.
* **cookingTimeMinutes:** (Optional) Estimated cooking time in minutes (integer).
* **difficulty:** (Optional) Difficulty level (e.g., "easy", "medium", "hard").

[I EMPHASIZE AGAIN: You must respond in English only]

Example JSON output for a single recipe:
{
  "dish_name": "{{mealName}}",
  "cost_information": "Approximately 5 dollar",
  "nutritional_information": {
    "calories": "350",
    "protein": "30g",
    "carbohydrates": "15g",
    "fats": "18g"
  },
  "ingredients": [
    {"name": "Main Ingredient for {{mealName}}", "quantity": "1 serving"}
  ],
  "seasonings": [
    {"name": "Basic Seasoning", "quantity": "to taste"}
  ],
  "cooking_instructions": [
    "Step 1 for {{mealName}}.",
    "Step 2 for {{mealName}}."
  ],
  "cookingTimeMinutes": 25,
  "difficulty": "medium"
}

Ensure the output is a single JSON object representing this one recipe.
    '''
  };

  // 메뉴 후보 생성 프롬프트 템플릿
  Map<String, String> menuCandidatesPromptTemplates = {
    'ko': '''
[중요: 반드시 한국어로만 응답하세요]

"{{mealType}}" 식사에 대한 {{count}}개의 메뉴 후보를 생성해주세요.
각 후보에는 다음 내용이 포함되어야 합니다:
- dish_name (문자열)
- category (문자열, 예: breakfast, lunch, dinner, snack)
- description (문자열, 1-2문장)
- calories (문자열)
- ingredients (문자열 목록)
- meal_type (문자열, 반드시 "{{mealType}}"이어야 함)

중요: 응답은 배열 형식의 유효한 JSON이어야 합니다.

[다시 한번 강조합니다: 반드시 한국어로만 응답하세요]

출력 형식 (JSON 배열):
[
  {
    "dish_name": "예시 메뉴명",
    "category": "{{mealType}}",
    "description": "간단한 설명",
    "calories": "대략적인 칼로리",
    "ingredients": ["재료1", "재료2"],
    "meal_type": "{{mealType}}"
  }
]
    ''',
    'en': '''
[IMPORTANT: You must respond in English only]

Generate {{count}} candidate dishes for "{{mealType}}".
Each candidate should include:
- dish_name (string)
- category (string, e.g., breakfast, lunch, dinner, snack)
- description (string, 1-2 sentences)
- calories (string)
- ingredients (list of strings)
- meal_type (string, must be: "{{mealType}}")

IMPORTANT: Make sure the response is valid JSON in an array format.

[I EMPHASIZE AGAIN: You must respond in English only]

Output format (JSON array):
[
  {
    "dish_name": "Example Dish Name",
    "category": "{{mealType}}",
    "description": "Brief description here",
    "calories": "Approximate calories",
    "ingredients": ["Ingredient 1", "Ingredient 2"],
    "meal_type": "{{mealType}}"
  }
]
    '''
  };

  // 언어 코드로 템플릿 조회
  String getTemplate(Map<String, String> templateMap, String langCode) {
    if (templateMap.containsKey(langCode)) {
      return templateMap[langCode]!;
    }
    return templateMap[defaultLanguage]!;
  }

  // 템플릿 내 변수 대체
  String processTemplate(String template, Map<String, String> variables) {
    String result = template;
    
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    
    return result;
  }
} 