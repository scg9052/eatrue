// services/menu_generation_service.dart
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/recipe.dart'; // Recipe 모델 import
import '../models/user_data.dart'; // UserData 모델 import

class MenuGenerationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';

  MenuGenerationService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  GenerationConfig _getBaseGenerationConfig({String? responseMimeType}) {
    return GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1,
      topP: 0.95,
      responseMimeType: responseMimeType,
    );
  }

  List<SafetySetting> _getSafetySettings() {
    // TODO: firebase_vertexai 패키지 버전에 맞는 정확한 HarmBlockThreshold 및 HarmBlockMethod 값으로 수정하세요.
    // 예: SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.block)
    return [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity ),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity ),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity ),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity ),
    ];
  }

  Future<dynamic> _callGenerativeModelForJson(
      String systemInstructionText, String userPrompt, {String? modelNameOverride}) async {
    try {
      final systemInstruction = Content.system(systemInstructionText);
      final model = _vertexAI.generativeModel(
        model: modelNameOverride ?? _modelName,
        generationConfig: _getBaseGenerationConfig(responseMimeType: 'application/json'),
        safetySettings: _getSafetySettings(),
        systemInstruction: systemInstruction,
      );
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      print("Vertex AI 응답 요청 완료. 데이터 확인 중...");
      
      if (response.text == null || response.text!.isEmpty) {
        print("오류: Vertex AI가 빈 응답을 반환했습니다.");
        return null;
      }

      print("응답 텍스트 길이: ${response.text!.length}자");
      print("응답 미리보기: ${response.text!.substring(0, response.text!.length > 100 ? 100 : response.text!.length)}...");
      
      try {
        // 백틱과 JSON 표시 제거
        String jsonString = response.text!.trim();
        if (jsonString.contains("```")) {
          jsonString = jsonString
              .replaceAll("```json", "")
              .replaceAll("```", "")
              .trim();
          print("백틱 제거 후 JSON 문자열: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...");
        }
        
        try {
          // JSON 파싱 시도
          final decoded = jsonDecode(jsonString);
          print("✅ JSON 파싱 성공");
          
          // 결과 처리 로직
          if (decoded is List) {
            return decoded;
          } else if (decoded is Map) {
            // 실패한 경우 명시적 오류 확인
            if (decoded.containsKey('error')) {
              print("API 오류 응답: ${decoded['error']}");
            }
            
            // candidates나 results 키가 있는지 확인
            final candidates = decoded['candidates'];
            final results = decoded['results'];
            if (candidates is List && candidates.isNotEmpty) return candidates;
            if (results is List && results.isNotEmpty) return results;
            
            // breakfast, lunch 등의 식사 키가 있는지 확인 (메뉴 생성 응답)
            if (decoded.containsKey('breakfast') || decoded.containsKey('lunch') || 
                decoded.containsKey('dinner') || decoded.containsKey('snacks')) {
              print("메뉴 응답 구조 확인됨");
              return decoded;
            }
            
            return decoded;
          }
          return decoded;
        } catch (jsonError) {
          print("⚠️ JSON 파싱 실패: $jsonError");
          
          // JSON 형식이 아닌 경우 응답 내에서 JSON 부분 추출 시도
          final jsonStart = response.text!.indexOf('{');
          final jsonArrayStart = response.text!.indexOf('[');
          final jsonEnd = response.text!.lastIndexOf('}');
          final jsonArrayEnd = response.text!.lastIndexOf(']');
          
          // 배열 형식 ([]) 추출 시도
          if (jsonArrayStart >= 0 && jsonArrayEnd > jsonArrayStart) {
            final extractedArray = response.text!.substring(jsonArrayStart, jsonArrayEnd + 1);
            print("JSON 배열 추출 시도: ${extractedArray.substring(0, extractedArray.length > 50 ? 50 : extractedArray.length)}...");
            
            try {
              final extracted = jsonDecode(extractedArray);
              print("✅ JSON 배열 추출 및 파싱 성공");
              return extracted;
            } catch (e) {
              print("⚠️ 추출된 JSON 배열 파싱 실패: $e");
              
              // JSON 배열 수동 복구 시도
              try {
                String fixedJson = extractedArray
                    .replaceAll("'", "\"")  // 작은따옴표를 큰따옴표로 변경
                    .replaceAll(",]", "]")  // 마지막 쉼표 제거
                    .replaceAll(",}", "}"); // 마지막 쉼표 제거
                    
                final extracted = jsonDecode(fixedJson);
                print("✅ JSON 배열 수동 수정 후 파싱 성공");
                return extracted;
              } catch (fixError) {
                print("⚠️ JSON 배열 수동 수정 실패: $fixError");
              }
            }
          }
          
          // 객체 형식 ({}) 추출 시도
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final extractedJson = response.text!.substring(jsonStart, jsonEnd + 1);
            print("JSON 구조 추출 시도: ${extractedJson.substring(0, extractedJson.length > 50 ? 50 : extractedJson.length)}...");
            
            try {
              final extracted = jsonDecode(extractedJson);
              print("✅ JSON 추출 및 파싱 성공");
              return extracted;
            } catch (e) {
              print("⚠️ 추출된 JSON 파싱 실패: $e");
              
              // 마지막 시도: 간단한 메뉴 구조 만들기
              print("기본 메뉴 구조 생성 시도");
              final result = _createFallbackMenuResponse();
              if (result != null) {
                print("✅ 기본 메뉴 구조 생성 성공");
                return result;
              }
            }
          }
          
          print("❌ 모든 JSON 복구 시도 실패");
          return null;
        }
      } catch (e) {
        print("❌ Vertex AI 응답 처리 중 오류: $e");
        return null;
      }
    } catch (e) {
      print("❌ Vertex AI 모델 호출 중 오류: $e");
      return null;
    }
  }
  
  // 모델 응답 실패 시 기본 메뉴 구조 생성
  Map<String, dynamic>? _createFallbackMenuResponse() {
    try {
      return {
        "breakfast": [
          {
            "dish_name": "오트밀 죽",
            "category": "breakfast",
            "description": "간단하고 영양가 높은 아침 식사"
          },
          {
            "dish_name": "계란 토스트",
            "category": "breakfast",
            "description": "단백질이 풍부한 아침 메뉴"
          },
          {
            "dish_name": "요거트 과일 볼",
            "category": "breakfast",
            "description": "신선한 과일과 요거트로 만든 건강식"
          }
        ],
        "lunch": [
          {
            "dish_name": "비빔밥",
            "category": "lunch",
            "description": "다양한 야채와 고기가 어우러진 한식 대표 메뉴"
          },
          {
            "dish_name": "샐러드와 통밀 빵",
            "category": "lunch",
            "description": "가볍고 건강한 점심 식사"
          },
          {
            "dish_name": "참치 김밥",
            "category": "lunch",
            "description": "단백질과 탄수화물의 균형 잡힌 한 끼"
          }
        ],
        "dinner": [
          {
            "dish_name": "닭가슴살 구이",
            "category": "dinner",
            "description": "저지방 고단백 저녁 식사"
          },
          {
            "dish_name": "두부 스테이크",
            "category": "dinner",
            "description": "식물성 단백질이 풍부한 건강식"
          },
          {
            "dish_name": "콩나물국밥",
            "category": "dinner",
            "description": "소화가 잘되는 가벼운 저녁 메뉴"
          }
        ],
        "snacks": [
          {
            "dish_name": "과일 믹스",
            "category": "snack", 
            "description": "다양한 비타민과 섬유질을 제공하는 간식"
          },
          {
            "dish_name": "견과류 믹스",
            "category": "snack",
            "description": "건강한 지방과 단백질이 풍부한 간식"
          },
          {
            "dish_name": "그릭 요거트",
            "category": "snack",
            "description": "단백질이 풍부한 가벼운 간식"
          }
        ]
      };
    } catch (e) {
      print("기본 메뉴 생성 중 오류: $e");
      return null;
    }
  }

  // 전체 메뉴 생성 API (기존 메소드)
  Future<Map<String, dynamic>?> generateMenu({
    required Map<String, dynamic> userRecommendedNutrients,
    required String summarizedDislikes,
    required String summarizedPreferences,
    Map<String, dynamic>? previousMenu,
    Map<String, String>? verificationFeedback,
  }) async {
    const systemInstructionText =
        'You are a nutrition expert and menu planner. Your task is to generate a meal plan (not recipes) based on the user\'s dietary requirements, preferences, and dislikes. The meal plan should include ONLY the dish name, category (breakfast, lunch, dinner, snack), and a short description. Do NOT include any cooking instructions, detailed ingredients, nutritional information, or seasonings. Absolutely NO recipe or cooking details should be generated at this stage.';
    final String specificModelNameForFullMenu = 'gemini-2.5-flash-preview-04-17';

    final nutrientsJson = jsonEncode(userRecommendedNutrients);
    final previousMenuJson = previousMenu != null ? jsonEncode(previousMenu) : "None";
    final verificationFeedbackJson = verificationFeedback != null ? jsonEncode(verificationFeedback) : "None";

    final userPrompt = '''
To generate a personalized meal plan, please consider the following information:

* Daily Recommended Nutrients: $nutrientsJson
* Summarized Dislikes: $summarizedDislikes
* Summarized Preferences: $summarizedPreferences
* Previous Menu (Optional, for regeneration): $previousMenuJson
* Verification Feedback (Optional, for regeneration): $verificationFeedbackJson

Follow these instructions to create the meal plan:
1.  **Meal Plan Generation:**
    * Create a meal plan that aligns with the user's daily calorie recommendation and recommended protein intake, specified in "Daily Recommended Nutrients".
    * Take into account the user's summarized dislikes and preferences to ensure the meal plan is personalized.
    * Provide three dish options for each meal (breakfast, lunch, dinner, and snacks).
    * If `previous_menu` and `verification_feedback` are provided, regenerate the meal plan, keeping the verified items and generating new options for the unverified ones. The `verification_feedback` will be in the format of "meal[index]" (e.g., "breakfast[0]", "lunch[2]") indicating the accepted menu items.
2.  **Details for Each Dish:**
    * For each dish, include ONLY the following fields:
        * **dish_name:** The name of the dish.
        * **category:** One of [breakfast, lunch, dinner, snack].
        * **description:** A short, appetizing description of the dish (1-2 sentences).
    * Do NOT include any cooking instructions, detailed ingredients, nutritional information, or seasonings. Absolutely NO recipe or cooking details should be generated at this stage.
3.  **Output Format:**
    * Present the meal plan in a JSON format, with "breakfast", "lunch", "dinner", and "snacks" as the main keys. Each key should contain a list of three dish options (dictionaries).
    * Ensure that all the required information is included for each dish.

Example Dish Item (within the JSON structure for one of the meals, e.g., "lunch"):
{
  "dish_name": "Grilled Chicken Salad",
  "category": "lunch",
  "description": "A fresh salad with grilled chicken breast, crisp greens, and a light vinaigrette."
}
Ensure that the generated meal plan includes ONLY the above details for each dish.
''';
    return await _callGenerativeModelForJson(systemInstructionText, userPrompt, modelNameOverride: specificModelNameForFullMenu);
  }

  // *** 새로운 메소드: 단일 음식명에 대한 상세 레시피 생성 ***
  Future<Recipe?> getSingleRecipeDetails({
    required String mealName,
    required UserData userData, // 사용자 정보를 받아 개인화된 레시피 생성
  }) async {
    const systemInstructionText =
        'You are a culinary expert. Your task is to provide a detailed recipe for a given dish name, considering user preferences and restrictions. The recipe should include a dish name, cost information, nutritional information, ingredients with quantities, seasonings with quantities, and step-by-step cooking instructions.';

    // 사용자 정보를 프롬프트에 활용
    final userPrompt = '''
Generate a detailed recipe for the following dish: "$mealName".

Please consider these user details for personalization:
* Allergies: ${userData.allergies.isNotEmpty ? userData.allergies.join(', ') : '없음'}
* Disliked Ingredients: ${userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : '없음'}
* Preferred Cooking Methods: ${userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : '제한 없음'}
* Available Cooking Tools: ${userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : '제한 없음'}
* Is Vegan: ${userData.isVegan ? '예' : '아니오'}
* Religious Dietary Restrictions: ${userData.isReligious ? (userData.religionDetails ?? '있음 (상세 정보 없음)') : '없음'}

The recipe should include the following details in JSON format:
* **dish_name:** The name of the dish (should be "$mealName").
* **cost_information:** An estimated cost to prepare the dish.
* **nutritional_information:** A breakdown of the dish's nutritional content (calories, protein, carbohydrates, fats as strings, and optionally vitamins, minerals as lists of strings).
* **ingredients:** A list of objects, each with "name" (string) and "quantity" (string).
* **seasonings:** A list of objects, each with "name" (string) and "quantity" (string).
* **cooking_instructions:** A list of strings, where each string is a step.
* **cookingTimeMinutes:** (Optional) Estimated cooking time in minutes (integer).
* **difficulty:** (Optional) Difficulty level (e.g., "쉬움", "보통", "어려움").

Example JSON output for a single recipe:
{
  "dish_name": "$mealName",
  "cost_information": "Approximately 5 dollar",
  "nutritional_information": {
    "calories": "350",
    "protein": "30g",
    "carbohydrates": "15g",
    "fats": "18g"
  },
  "ingredients": [
    {"name": "Main Ingredient for $mealName", "quantity": "1 serving"}
  ],
  "seasonings": [
    {"name": "Basic Seasoning", "quantity": "to taste"}
  ],
  "cooking_instructions": [
    "Step 1 for $mealName.",
    "Step 2 for $mealName."
  ],
  "cookingTimeMinutes": 25,
  "difficulty": "보통"
}

Ensure the output is a single JSON object representing this one recipe.
''';
    final Map<String, dynamic>? jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse != null) {
      try {
        // Recipe.fromJson이 이 JSON 구조를 파싱할 수 있도록 Recipe 모델 확인/수정 필요
        return Recipe.fromJson(jsonResponse);
      } catch (e) {
        print("단일 레시피 JSON 파싱 오류: $e. 원본 JSON: $jsonResponse");
        return null;
      }
    }
    return null;
  }

  Future<List<SimpleMenu>> generateMealCandidates({required String mealType, int count = 3}) async {
    const systemInstructionText =
        'You are a nutrition expert and menu planner. Your task is to generate meal candidates for a specific meal type. Each candidate should include dish_name, category, description, calories, and ingredients (as a list of strings).';

    final userPrompt = '''
Generate $count candidate dishes for "$mealType".
Each candidate should include:
- dish_name (string)
- category (string, e.g., breakfast, lunch, dinner, snack)
- description (string, 1-2 sentences)
- calories (string)
- ingredients (list of strings)
- meal_type (string, must be: "$mealType")

IMPORTANT: Make sure the response is valid JSON in an array format.

Output format (JSON array):
[
  {
    "dish_name": "Example Dish Name",
    "category": "$mealType",
    "description": "Brief description here",
    "calories": "Approximate calories",
    "ingredients": ["Ingredient 1", "Ingredient 2"],
    "meal_type": "$mealType"
  }
]
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse == null) {
      print("메뉴 후보 생성 실패, 기본 메뉴 반환");
      return _getDefaultCandidates(mealType, count);
    }

    try {
      List<dynamic> menuList;
      
      // JSON 응답이 List인 경우 직접 사용
      if (jsonResponse is List) {
        menuList = jsonResponse;
      } 
      // JSON 응답이 Map인 경우 candidates 또는 results 키에서 List 추출
      else if (jsonResponse is Map) {
        final candidates = jsonResponse['candidates'];
        final results = jsonResponse['results'];
        
        if (candidates is List) {
          menuList = candidates;
        } else if (results is List) {
          menuList = results;
        } else {
          // Map의 값들을 List로 변환
          print("예상치 못한 응답 구조, 기본 메뉴 반환");
          return _getDefaultCandidates(mealType, count);
        }
      } else {
        print("예상치 못한 JSON 응답 형식: $jsonResponse");
        return _getDefaultCandidates(mealType, count);
      }

      // List를 SimpleMenu 객체 리스트로 변환
      final List<SimpleMenu> results = [];
      
      for (var item in menuList) {
        try {
          if (item is Map<String, dynamic>) {
            // 필수 필드 확인 및 보완
            if (!item.containsKey('meal_type') && !item.containsKey('mealType')) {
              item['meal_type'] = mealType;
            }
            
            if (!item.containsKey('category') || item['category'] == null || 
                item['category'].toString().isEmpty) {
              item['category'] = mealType;
            }
            
            if (!item.containsKey('dish_name') || item['dish_name'] == null || 
                item['dish_name'].toString().isEmpty) {
              item['dish_name'] = "메뉴 ${results.length + 1}";
            }
            
            if (!item.containsKey('description') || item['description'] == null || 
                item['description'].toString().isEmpty) {
              item['description'] = "${item['dish_name']} 메뉴입니다.";
            }
            
            final menu = SimpleMenu.fromJson(item);
            results.add(menu);
          } else {
            print("잘못된 메뉴 항목 형식: $item");
          }
        } catch (e) {
          print("메뉴 항목 파싱 오류: $e");
        }
      }
      
      if (results.isEmpty) {
        print("메뉴 후보 생성 결과가 없어 기본 메뉴 반환");
        return _getDefaultCandidates(mealType, count);
      }
      
      return results;
    } catch (e) {
      print("메뉴 후보 JSON 파싱 오류: $e. 원본 JSON: $jsonResponse");
      return _getDefaultCandidates(mealType, count);
    }
  }
  
  List<SimpleMenu> _getDefaultCandidates(String mealType, int count) {
    List<SimpleMenu> defaults = [];
    
    switch (mealType) {
      case 'breakfast':
        defaults = [
          SimpleMenu(
            dishName: "오트밀 죽",
            category: "breakfast",
            description: "간단하고 영양가 높은 아침 식사",
            mealType: "breakfast",
            calories: "약 250kcal",
            ingredients: ["오트밀", "우유", "꿀", "시나몬"]
          ),
          SimpleMenu(
            dishName: "계란 토스트",
            category: "breakfast",
            description: "단백질이 풍부한 아침 메뉴",
            mealType: "breakfast",
            calories: "약 350kcal",
            ingredients: ["빵", "계란", "치즈", "버터"]
          ),
          SimpleMenu(
            dishName: "요거트 과일 볼",
            category: "breakfast",
            description: "신선한 과일과 요거트로 만든 건강식",
            mealType: "breakfast",
            calories: "약 200kcal",
            ingredients: ["요거트", "바나나", "블루베리", "그래놀라"]
          ),
        ];
        break;
      case 'lunch':
        defaults = [
          SimpleMenu(
            dishName: "비빔밥",
            category: "lunch",
            description: "다양한 야채와 고기가 어우러진 한식 대표 메뉴",
            mealType: "lunch",
            calories: "약 450kcal",
            ingredients: ["밥", "소고기", "당근", "시금치", "버섯", "고추장"]
          ),
          SimpleMenu(
            dishName: "샐러드와 통밀 빵",
            category: "lunch",
            description: "가볍고 건강한 점심 식사",
            mealType: "lunch",
            calories: "약 350kcal",
            ingredients: ["양상추", "토마토", "오이", "통밀빵", "올리브 오일"]
          ),
          SimpleMenu(
            dishName: "참치 김밥",
            category: "lunch",
            description: "단백질과 탄수화물의 균형 잡힌 한 끼",
            mealType: "lunch",
            calories: "약 400kcal",
            ingredients: ["밥", "김", "참치", "당근", "오이", "계란"]
          ),
        ];
        break;
      case 'dinner':
        defaults = [
          SimpleMenu(
            dishName: "닭가슴살 구이",
            category: "dinner",
            description: "저지방 고단백 저녁 식사",
            mealType: "dinner",
            calories: "약 380kcal",
            ingredients: ["닭가슴살", "로즈마리", "마늘", "올리브 오일", "야채"]
          ),
          SimpleMenu(
            dishName: "두부 스테이크",
            category: "dinner",
            description: "식물성 단백질이 풍부한 건강식",
            mealType: "dinner",
            calories: "약 330kcal",
            ingredients: ["두부", "버섯", "양파", "간장 소스"]
          ),
          SimpleMenu(
            dishName: "콩나물국밥",
            category: "dinner",
            description: "소화가 잘되는 가벼운 저녁 메뉴",
            mealType: "dinner",
            calories: "약 400kcal",
            ingredients: ["쌀", "콩나물", "청양고추", "달걀", "들깻가루"]
          ),
        ];
        break;
      default:
        defaults = [
          SimpleMenu(
            dishName: "과일 믹스",
            category: "snack",
            description: "다양한 비타민과 섬유질을 제공하는 간식",
            mealType: "snack",
            calories: "약 120kcal",
            ingredients: ["사과", "바나나", "오렌지", "키위"]
          ),
          SimpleMenu(
            dishName: "견과류 믹스",
            category: "snack",
            description: "건강한 지방과 단백질이 풍부한 간식",
            mealType: "snack",
            calories: "약 180kcal",
            ingredients: ["아몬드", "호두", "해바라기씨", "건포도"]
          ),
          SimpleMenu(
            dishName: "그릭 요거트",
            category: "snack",
            description: "단백질이 풍부한 가벼운 간식",
            mealType: "snack",
            calories: "약 150kcal",
            ingredients: ["그릭 요거트", "꿀", "견과류"]
          ),
        ];
    }
    
    // 요청된 수만큼 반환
    return defaults.take(count).toList();
  }
}
