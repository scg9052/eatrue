// services/menu_verification_service.dart
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/user_data.dart'; // UserData 클래스 임포트 추가
// import 'dart:typed_data';

class MenuVerificationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';

  MenuVerificationService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  Future<dynamic> verifyMenu({ // 반환 타입은 String "True" 또는 Map<String, String> 일 수 있음
    required String userPreferences,
    required String userDislikes,
    required Map<String, dynamic> userRecommendedNutrients, // "calories", "protein"
    required Map<String, dynamic> customizedDietPlan, // 메뉴 생성 API의 출력과 동일한 구조
    UserData? userData, // 사용자 상세 정보 추가
  }) async {
    // API 스펙의 "seed" 파라미터 관련 예외는 제거했습니다.
    final generationConfig = GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 0, // 검증 작업이므로 낮은 temperature가 적합할 수 있음
      topP: 0.95,
      // responseMimeType: 'application/json', // 응답이 "True" 또는 JSON 객체이므로, 항상 JSON은 아님
    );

    final safetySettings = [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
    ];

    const siText1 =
        'You are an expert diet plan evaluator. Your task is to meticulously review a user\'s customized diet plan against their stated preferences and dislikes to identify any conflicts.';
    final systemInstruction = Content.system(siText1);

    final model = _vertexAI.generativeModel(
      model: _modelName, // API 스펙에 명시된 모델 사용
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      systemInstruction: systemInstruction,
    );

    final nutrientsJson = jsonEncode(userRecommendedNutrients);
    final dietPlanJson = jsonEncode(customizedDietPlan);

    // 사용자 상세 정보가 있는 경우
    String userDataInfo = '';
    if (userData != null) {
      userDataInfo = '''
Additional User Details:
- Age: ${userData.age ?? 'Not specified'}
- Gender: ${userData.gender ?? 'Not specified'}
- Height: ${userData.height != null ? '${userData.height}cm' : 'Not specified'}
- Weight: ${userData.weight != null ? '${userData.weight}kg' : 'Not specified'}
- Activity Level: ${userData.activityLevel ?? 'Normal'}
- Favorite Foods: ${userData.favoriteFoods.isNotEmpty ? userData.favoriteFoods.join(', ') : 'No specific preferences'}
- Disliked Foods: ${userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : 'No specific dislikes'}
- Preferred Cooking Methods: ${userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : 'No specific preferences'}
- Available Cooking Tools: ${userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : 'Basic cooking tools'}
- Allergies: ${userData.allergies.isNotEmpty ? userData.allergies.join(', ') : 'None'}
- Is Vegan: ${userData.isVegan ? 'Yes' : 'No'}
- Religious Restrictions: ${userData.isReligious ? (userData.religionDetails ?? 'Yes') : 'None'}
- Meal Purpose: ${userData.mealPurpose.isNotEmpty ? userData.mealPurpose.join(', ') : 'General meals'}
- Budget: ${userData.mealBudget != null ? '${userData.mealBudget} KRW' : 'Not specified'}
- Preferred Cooking Time: ${userData.preferredCookingTime != null ? 'Within ${userData.preferredCookingTime} minutes' : 'No limitation'}
- Preferred Ingredients: ${userData.preferredIngredients.isNotEmpty ? userData.preferredIngredients.join(', ') : 'No specific preferences'}
- Preferred Seasonings: ${userData.preferredSeasonings.isNotEmpty ? userData.preferredSeasonings.join(', ') : 'No specific preferences'}
- Preferred Cooking Styles: ${userData.preferredCookingStyles.isNotEmpty ? userData.preferredCookingStyles.join(', ') : 'No specific preferences'}
- Disliked Ingredients: ${userData.dislikedIngredients.isNotEmpty ? userData.dislikedIngredients.join(', ') : 'No specific dislikes'}
- Disliked Seasonings: ${userData.dislikedSeasonings.isNotEmpty ? userData.dislikedSeasonings.join(', ') : 'No specific dislikes'}
- Disliked Cooking Styles: ${userData.dislikedCookingStyles.isNotEmpty ? userData.dislikedCookingStyles.join(', ') : 'No specific dislikes'}
''';
    }

    final userPrompt = '''
You will be provided with the following information:

* User Preferences: $userPreferences
* User Dislikes: $userDislikes
* User's Recommended Nutrients: $nutrientsJson
* Customized Diet Plan (in JSON format): $dietPlanJson
${userDataInfo.isNotEmpty ? '* $userDataInfo' : ''}

Follow these steps to evaluate the diet plan:

1.  Carefully examine the user's preferences, dislikes, and recommended nutrients. Consider the available cooking tools to determine if the recipes are feasible. Note that dislikes generally refer to specific ingredients or dishes, not cooking tools.
2.  Thoroughly review the customized diet plan, paying close attention to the ingredients, nutritional information, cost, and preparation methods for each meal (Breakfast, Lunch, Dinner, and Snacks). When verifying nutritional components, assess whether individual meals (Breakfast, Lunch, Dinner and Snacks) meet the nutrient requirements, rather than evaluating the entire diet plan as a whole.
3.  Identify any instances where individual meals in the diet plan significantly conflict with the user's stated preferences or dislikes, or do not meet the user's recommended nutrients. A conflict occurs if a meal includes ingredients the user dislikes, does not align with their preferences, or does not provide the recommended nutrients. Specifically, ensure that the preparation methods are feasible with the user's available cooking tools. For example, a recipe requiring an oven would conflict if the user does not have an oven. **Only consider the dislikes provided in the "User Dislikes" section. Do not hallucinate any dislikes.**
4.  If any conflicts are found, output a JSON object with the specific meals that violate the user's preferences, dislikes, or nutrient recommendations as keys, and the reasons for the violation as values. The keys should be in the format: "Breakfast[1]", "Dinner[2]", "Snack[0]", where the numbers in brackets represent the index of the conflicting meal within each category (Breakfast, Lunch, Dinner, Snack), starting from 0. Ensure the output is a valid JSON object. **Ensure the reasons for the violation are accurate, professionally worded, and concise. Be as brief as possible while maintaining clarity. If a meal exceeds the recommended calorie intake by more than 150 calories, specify by how much and include the calculation (actual calories - recommended calories = excess calories) (e.g., "Exceeds recommended calorie intake for breakfast by 200 calories (400 calories - 200 calories)."). Do not flag meals for minor calorie discrepancies (less than or equal to 150 calories).**
5.  If the customized diet plan does not conflict with the user's preferences, dislikes, or nutrient recommendations, output only "True".

Important Considerations:

* 'Preferred cooking methods' means the user prefers not to use other methods besides the listed ones. **You MUST be extremely lenient about this preference; strict adherence is absolutely not required. Only flag a meal if it uses a cooking method that the user explicitly dislikes, *and* the user does not have the tools for it. Before flagging a meal due to cooking methods, ALWAYS check if the user has the necessary tools. Do not, under any circumstances, flag a meal simply because it deviates from the user's preferred cooking methods if they possess the necessary cooking tools. If the user has the tools, it is NOT a conflict, even if the method isn't preferred. Focus *exclusively* on explicit dislikes regarding cooking methods and missing tools. To reiterate, a meal should *only* be flagged due to cooking methods if the user explicitly dislikes the method *and* lacks the necessary tool. If the user has the tool, it is NOT a conflict.**
* Based on the list of cooking tools, determine if each recipe step is feasible with the available tools.
* Verify that the calories and key nutrients (protein) of each meal align with the user's recommended intake for individual meals, not the total daily intake. **Do not flag meals based on the percentage of daily nutrients they provide. Evaluate each meal based on whether the absolute values of calories and protein are reasonable for a single meal, given the user's overall daily recommendations.**

Output Requirements:

* The response must be professional and concise.
* The response must be strictly in JSON format as described in step 4, or "True" if there are no conflicts. **Do not include any additional explanations or conversational text outside of the JSON object.**
* **Ensure the response is only in English.**
''';

    try {
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      print("Menu Verification API Response: ${response.text}");

      if (response.text != null) {
        if (response.text!.trim().toLowerCase() == 'true') {
          return true; // 문자열 "True"를 boolean true로 반환
        }
        try {
          // JSON 객체인 경우 파싱 시도
          final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          // "True"도 아니고 JSON 파싱도 실패하면, 원본 텍스트를 반환하거나 오류 처리
          print("Menu Verification API response is not 'True' and not valid JSON: ${response.text}");
          return response.text; // 또는 null 또는 예외 발생
        }
      }
      return null;
    } catch (e) {
      print("Error calling Menu Verification API: $e");
      return null;
    }
  }
}
