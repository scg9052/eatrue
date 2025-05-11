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
      print("Vertex AI JSON 응답 (${userPrompt.substring(0, (userPrompt.length < 20 ? userPrompt.length : 20) )}...): ${response.text}");
      if (response.text != null) {
        try {
          final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
          final decoded = jsonDecode(jsonString);
          // List인 경우 그대로 반환, Map인 경우 candidates 또는 results 키의 값을 반환
          if (decoded is List) {
            return decoded;
          } else if (decoded is Map) {
            final candidates = decoded['candidates'];
            final results = decoded['results'];
            if (candidates is List) return candidates;
            if (results is List) return results;
            return decoded;
          }
          return decoded;
        } catch (e) {
          print("Vertex AI 응답 JSON 파싱 오류: $e. 원본 텍스트: ${response.text}");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Vertex AI (JSON) 모델 호출 중 오류: $e");
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

Output format (JSON array):
[
  {
    "dish_name": "...",
    "category": "...",
    "description": "...",
    "calories": "...",
    "ingredients": ["...", "..."]
  },
  ...
]
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse == null) return [];

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
          menuList = jsonResponse.values.where((value) => value is Map).toList();
        }
      } else {
        print("예상치 못한 JSON 응답 형식: $jsonResponse");
        return [];
      }

      // List를 SimpleMenu 객체 리스트로 변환
      return menuList.map((item) {
        if (item is Map<String, dynamic>) {
          return SimpleMenu.fromJson(item);
        }
        print("잘못된 메뉴 항목 형식: $item");
        return null;
      }).whereType<SimpleMenu>().toList();
    } catch (e) {
      print("메뉴 후보 JSON 파싱 오류: $e. 원본 JSON: $jsonResponse");
      return [];
    }
  }
}
